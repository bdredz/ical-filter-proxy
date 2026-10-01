require 'spec_helper'

RSpec.describe IcalFilterProxy::Calendar do
  let(:url) { 'http://example.com/ical.ics' }
  let(:api_key) { 'abc123' }
  let(:cal) { described_class.new(url, api_key) }

  describe '.new' do
    it 'accepts a URL as its first arg' do
      expect(cal.ical_url).to eq(url)
    end

    it 'accepts an API key as it\'s second arg' do
      expect(cal.api_key).to eq(api_key)
    end

    it 'sets UTC as the default timezone' do
      expect(cal.timezone).to eq('UTC')
    end

    it 'optionally accepts a timezone as its third arg' do
      tz = 'Europe/London'
      cal = described_class.new(url, api_key, tz)

      expect(cal.timezone).to eq(tz)
    end

    it 'starts with an empty array of filter rules' do
      expect(cal.filter_rules.length).to eq(0)
    end

    describe '#add_rule' do
      it 'adds a new rule to the filter_rules array' do
        cal.add_rule('start_time', 'equals', '09:00')

        expect(cal.filter_rules.length).to eq(1)
      end
    end

    describe '#filtered_calendar' do
      before(:each) do
        @stub = stub_request(:get, "http://example.com/ical.ics").to_return(body: original_calendar)
      end

      it 'fetches the original calendar from the ical_url' do
        cal.filtered_calendar
        expect(@stub).to have_been_requested
      end

      it 'outputs a fresh calendar with only the events that match the filter_rules and the original alarm' do
        cal.add_rule('start_time', 'equals', '10:00')

        filtered_ical = cal.filtered_calendar
        expect(filtered_ical.gsub("\r\n", "\n")).to eq(filtered_calendar_with_original_alarm.gsub("\r\n", "\n"))
      end

      it 'outputs a fresh calendar with only the events that match the filter_rules and removed alarms' do
        cal.add_rule('start_time', 'equals', '10:00')
        cal.clear_existing_alarms = true

        filtered_ical = cal.filtered_calendar
        expect(filtered_ical.gsub("\r\n", "\n")).to eq(filtered_calendar_without_alarm.gsub("\r\n", "\n"))
      end

      it 'outputs a fresh calendar with only the events that match the filter_rules and new alarm' do
        cal.add_rule('start_time', 'equals', '10:00')
        cal.clear_existing_alarms = true
        cal.add_alarm_trigger("1 day")

        filtered_ical = cal.filtered_calendar
        expect(filtered_ical.gsub(/[\r\n]+/, "\n")).to eq(filtered_calendar_with_new_alarm.gsub(/[\r\n]+/, "\n"))
      end

      it 'appends extra events as all-day events that bypass the filter_rules' do
        cal.add_rule('summary', 'equals', 'no event has this summary')
        cal.add_extra_event('No School', '2027-01-04', '2027-01-05', 'Student holiday')

        events = Icalendar::Calendar.parse(cal.filtered_calendar).first.events
        expect(events.length).to eq(1)
        expect(events.first.summary).to eq('No School')
        expect(events.first.description).to eq('Student holiday')
        expect(events.first.dtstart).to eq(Date.new(2027, 1, 4))
        expect(events.first.dtend).to eq(Date.new(2027, 1, 6))
      end

      it 'does not accumulate alarms on extra events across renders' do
        cal.add_rule('summary', 'equals', 'no event has this summary')
        cal.add_extra_event('No School', '2027-01-04')
        cal.add_alarm_trigger('1 day')

        cal.filtered_calendar
        events = Icalendar::Calendar.parse(cal.filtered_calendar).first.events
        expect(events.first.alarms.length).to eq(1)
      end
    end

    describe 'name' do
      before { stub_request(:get, url).to_return(body: original_calendar) }

      it 'sets X-WR-CALNAME when a name is given' do
        cal.name = 'Team Rota'
        expect(cal.filtered_calendar).to include("X-WR-CALNAME:Team Rota\r\n")
      end

      it 'omits X-WR-CALNAME by default' do
        expect(cal.filtered_calendar).not_to include('X-WR-CALNAME')
      end
    end

    describe '#add_extra_event' do
      it 'rejects an end_date before the date' do
        expect { cal.add_extra_event('Bad', '2027-01-04', '2027-01-03') }.to raise_error(/end_date is before date/)
      end
    end
  end

  private

  def original_calendar
    File.read(File.expand_path('../fixtures/original_calendar.ics', __FILE__))
  end

  def filtered_calendar_with_original_alarm
    File.read(File.expand_path('../fixtures/filtered_calendar_with_original_alarm.ics', __FILE__))
  end

  def filtered_calendar_without_alarm
    File.read(File.expand_path('../fixtures/filtered_calendar_without_alarm.ics', __FILE__))
  end

  def filtered_calendar_with_new_alarm
    File.read(File.expand_path('../fixtures/filtered_calendar_with_new_alarm.ics', __FILE__))
  end
end
