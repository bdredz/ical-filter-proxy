module IcalFilterProxy
  class CalendarBuilder

    attr_reader :calendar_config, :calendar

    def initialize(calendar_config)
      @calendar_config = calendar_config
    end

    def build
      create_calendar
      add_rules
      add_alarms
      add_extra_events

      calendar
    end

    private

    def create_calendar
      @calendar = Calendar.new(calendar_config["ical_url"],
                               calendar_config["api_key"],
                               calendar_config["timezone"])
    end

    def add_rules
      rules = calendar_config["rules"]
      return unless rules

      rules.each do |rule|
        calendar.add_rule(rule["field"],
                          rule["operator"],
                          rule["val"])
      end
    end

    def add_alarms
      alarms = calendar_config["alarms"]
      return unless alarms

      calendar.clear_existing_alarms = true if alarms['clear_existing']

      triggers = alarms["triggers"]
      return unless triggers

      triggers.each do |trigger|
        calendar.add_alarm_trigger(trigger)
      end
    end

    def add_extra_events
      extra_events = calendar_config["extra_events"]
      return unless extra_events

      extra_events.each do |event|
        calendar.add_extra_event(event["summary"],
                                 event["date"],
                                 event["end_date"],
                                 event["description"])
      end
    end

  end
end
