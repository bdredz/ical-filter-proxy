require 'spec_helper'

# Guards the deployed config.yml against a snapshot of the real GCPS feed.
RSpec.describe 'config.yml gwinnett-school calendar' do
  let(:fixture) { File.read(File.expand_path('fixtures/gcps_district_events.ics', __dir__), encoding: 'UTF-8') }
  let(:calendar) { IcalFilterProxy.calendars.fetch('gwinnett-school') }
  let(:events) do
    stub_request(:get, calendar.ical_url).to_return(body: fixture)
    Icalendar::Calendar.parse(calendar.filtered_calendar).first.events
  end
  let(:kept) { events.map { |e| [e.dtstart.to_date.to_s, e.summary.to_s] }.sort }

  it 'keeps exactly the school-operations events' do
    expect(kept).to eq([
      ['2026-09-18', 'Digital Learning Day'],
      ['2026-10-28', 'Early Release for Elementary and Middle School'],
      ['2026-11-03', 'Digital Learning Day'],
      ['2026-12-16', 'Early Release for High Schools'],
      ['2026-12-18', 'End of the 1st Semester'],
      ['2027-01-05', 'Beginning of 2nd Semester'],
      ['2027-03-03', 'Early Release for Elementary and Middle Schools'],
      ['2027-03-19', 'Digital Learning Day'],
      ['2027-05-24', 'Early Release Days for High Schools'],
      ['2027-05-26', 'Last Day of School']
    ])
  end

  it 'drops holidays, breaks, board meetings and look-alike titles' do
    summaries = kept.map(&:last)
    [
      'Fall Break (School Holiday)', 'Winter Break (School Holiday)', 'Spring Break',
      'Labor Day (Systemwide Holiday)', 'School Board Business Meeting',
      'First Day of Autumn', 'First Day of Navaratri', 'Learning Disabilities Awareness Month Begins'
    ].each { |s| expect(summaries).not_to include(s) }
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
