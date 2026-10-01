module IcalFilterProxy
  class Calendar
    attr_accessor :ical_url, :api_key, :timezone, :filter_rules, :clear_existing_alarms, :alarm_triggers, :extra_events, :name

    def initialize(ical_url, api_key, timezone = 'UTC')
      self.ical_url = ical_url
      self.api_key = api_key
      self.timezone = timezone

      self.filter_rules = []
      self.clear_existing_alarms = false
      self.alarm_triggers = []
      self.extra_events = []
    end

    def add_rule(field, operator, value)
      self.filter_rules << FilterRule.new(field, operator, value)
    end

    def add_alarm_trigger(alarm_trigger)
      self.alarm_triggers << AlarmTrigger.new(alarm_trigger)
    end

    # Adds an all-day event that is not in the source feed. It bypasses filter rules.
    # end_date is inclusive and defaults to date.
    def add_extra_event(summary, date, end_date = nil, description = nil)
      start_date = Date.iso8601(date.to_s)
      last_date = end_date ? Date.iso8601(end_date.to_s) : start_date
      raise "extra event end_date is before date: #{summary}" if last_date < start_date

      self.extra_events << { summary: summary, start_date: start_date, last_date: last_date, description: description }
    end

    def filtered_calendar
      filtered_calendar = Icalendar::Calendar.new
      filtered_calendar.append_custom_property('X-WR-CALNAME', name) if name

      (filtered_events + built_extra_events).each do |event|
        filtered_calendar.add_event(event)
      end

      filtered_calendar.events.select do |e|
        e.alarms.clear if clear_existing_alarms
        alarm_triggers.each do |t|
          e.alarm do |a|
            a.action = "DISPLAY"
            a.description = e.summary
            a.trigger = t.alarm_trigger
          end
        end
      end

      filtered_calendar.to_ical
    end

    private

    def filtered_events
      original_ics.events.select do |e|
        filter_match?(FilterableEventAdapter.new(e, timezone: timezone))
      end
    end

    # Built per render so alarms added below never accumulate across requests.
    def built_extra_events
      extra_events.map do |extra|
        Icalendar::Event.new.tap do |e|
          e.uid = "extra-#{Digest::SHA1.hexdigest("#{extra[:summary]}|#{extra[:start_date]}")}@ical-filter-proxy"
          e.dtstart = Icalendar::Values::Date.new(extra[:start_date].strftime('%Y%m%d'))
          e.dtend = Icalendar::Values::Date.new((extra[:last_date] + 1).strftime('%Y%m%d'))
          e.summary = extra[:summary]
          e.description = extra[:description] if extra[:description]
        end
      end
    end

    def filter_match?(event)
      filter_rules.empty? || filter_rules.all? { |rule| rule.match_event?(event) }
    end

    def original_ics
      Icalendar::Calendar.parse(raw_original_ical).first
    end

    def raw_original_ical
      URI.open(ical_url).read
    end
  end
end
