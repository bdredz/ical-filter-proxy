require 'spec_helper'

# Guards the deployed config.yml against a snapshot of the real GCPS feed.
RSpec.describe 'config.yml gwinnett-school calendar' do
  let(:fixture) { File.read(File.expand_path('fixtures/gcps_district_events.ics', __dir__), encoding: 'UTF-8') }
  let(:calendar) { IcalFilterProxy.calendars.fetch('gwinnett-school') }
  let(:events) do
    stub_request(:get, calendar.ical_url).to_return(body: fixture)
    Icalendar::Calendar.parse(calendar.filtered_calendar).first.events
  end

  let(:spans) { events.map { |e| [e.summary.to_s, e.dtstart.to_date.to_s, (e.dtend.to_date - 1).to_s] }.sort_by { |x| x[1] } }

  # Every school date on the official 2026-27 GCPS calendar PDF from the feed's start onward,
  # as [summary, first day, last day inclusive].
  it 'matches the official 2026-27 calendar exactly' do
    expect(spans).to eq([
      ['Digital Learning Day', '2026-09-18', '2026-09-18'],
      ['Fall Break (School Holiday)', '2026-10-12', '2026-10-16'],
      ['Early Release for Elementary and Middle School', '2026-10-28', '2026-10-29'],
      ['Digital Learning Day', '2026-11-03', '2026-11-03'],
      ['Thanksgiving Break (School Holiday)', '2026-11-23', '2026-11-27'],
      ['Early Release for High Schools', '2026-12-16', '2026-12-18'],
      ['End of the 1st Semester', '2026-12-18', '2026-12-18'],
      ['Winter Break (School Holiday)', '2026-12-21', '2027-01-01'],
      ['Teacher Planning/Staff Development (Student Holiday)', '2027-01-04', '2027-01-04'],
      ['Beginning of 2nd Semester', '2027-01-05', '2027-01-05'],
      ['100th Day of School', '2027-01-22', '2027-01-22'],
      ['Student/Teacher Holidays (School Holiday)', '2027-02-12', '2027-02-16'],
      ['Early Release for Elementary and Middle Schools', '2027-03-03', '2027-03-04'],
      ['Digital Learning Day', '2027-03-19', '2027-03-19'],
      ['Spring Break', '2027-04-05', '2027-04-09'],
      ['Early Release Days for High Schools', '2027-05-24', '2027-05-26'],
      ['Last Day of School', '2027-05-26', '2027-05-26']
    ])
  end

  it 'drops general holidays, board meetings and look-alike titles' do
    summaries = spans.map(&:first)
    [
      'Labor Day (Systemwide Holiday)', 'Martin Luther King Jr. Day (Federal observance) (Student/staff holiday)',
      'Memorial Day (Staff holiday) {All staff}', 'Christmas Day (Christian)', 'Thanksgiving Day',
      'Juneteenth (Staff Holiday)', 'School Board Business Meeting', 'National School Breakfast Week Begins',
      'First Day of Autumn', 'First Day of Navaratri', 'Learning Disabilities Awareness Month Begins'
    ].each { |s| expect(summaries).not_to include(s) }
  end

  it 'names the calendar for subscribers' do
    stub_request(:get, calendar.ical_url).to_return(body: fixture)
    expect(calendar.filtered_calendar).to include("X-WR-CALNAME:Gwinnett School Calendar 2026-27")
  end

  it 'gives the added Jan 4 event a stable all-day UID' do
    jan4 = events.find { |e| e.dtstart.to_date.to_s == '2027-01-04' }
    expect(jan4.dtstart).to be_a(Icalendar::Values::Date)
    expect(jan4.uid.to_s).to eq(
      Icalendar::Calendar.parse(calendar.filtered_calendar).first.events.find { |e| e.uid.to_s.start_with?('extra-') }.uid.to_s
    )
  end

  it 'matches future wording from the printed calendar' do
    rule = calendar.filter_rules.first
    [
      'First Day of School', 'Required Pre-planning/Staff Development',
      'Teacher Post-planning/Staff Development', 'Teacher Planning/Staff Development'
    ].each do |s|
      expect(rule.match_event?(double(summary: s))).to be_truthy, s
    end
  end
end
