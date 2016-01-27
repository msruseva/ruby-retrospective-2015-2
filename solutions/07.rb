module LazyMode

  class Date

    attr_accessor :year, :month, :day

    def initialize(date)
      @year, @month, @day = parse(date)
    end

    def parse(date)
      date.split('-').map(&:to_i)
    end

    def to_s
      "%04d-%02d-%02d" % [@year, @month, @day]
    end

    def ==(other)
      @year == other.year and @month == other.month and @day == other.day
    end

    def same_week(other)
      week, date = [], other
      1.upto(7) do
        week << date
        date = date.next
      end
      week.include? self
    end

    def next
      new_year, new_month, new_day = @year, @month, @day + 1
      if new_day == 31
        new_day, new_month = 1, new_month + 1
      end
      if new_month == 13
        new_month, new_year = 1, new_year + 1
      end
      Date.new("#{new_year}-#{new_month}-#{new_day}")
    end


    def >(other)
      @year > other.year or @month > other.month or @day > other.day
    end

    def repeat(days)
      new_date = self.dup
      1.upto(days) { new_date = new_date.next }
      new_date
    end
  end

  class Note

    attr_accessor :header, :file, :tags, :status, :body, :date

    def initialize(header, file, *tags, &block)
      @header = header
      @file = file
      @tags = tags
      @status = :topostpone
      @body = ""
      instance_eval &block
    end

    def status(symbol = nil)
      if symbol.nil?
        @status
      else
        @status = symbol
      end
    end

    def body(text = nil)
      if text.nil?
        @body
      else
        @body = text
      end
    end

    def scheduled(date)
      if match = date.match(/\+(\d+)([mdw])$/)
        mapping = {'d' => 1, 'w' => 7, 'm' => 30}
        @repeat_by = match[1].to_i * mapping[match[2]]
      end
      @date = Date.new(date)
    end

    def scheduled_for_day(date)
      return date == @date if @repeat_by.nil?
      while date > @date
        @date = @date.repeat(@repeat_by)
      end
      date == @date
    end

    def scheduled_for_week(date)
      return @date.same_week(date) if @repeat_by.nil?
      while date > @date
        @date = @date.repeat(@repeat_by)
      end
      @date.same_week(date)
    end

    def file_name
      file.name
    end

    def note(header, *tags, &block)
      file.inner_note(header, *tags, &block)
    end
  end

  class File
    attr_accessor :name, :notes

    def initialize(name, &block)
      @name = name
      @notes = []
      @inner_note = []
      instance_eval &block
      @notes = @notes + @inner_note
      @inner_note = []
    end

    def note(header, *tags, &block)
      @notes << Note.new(header, self, *tags, &block)
    end

    def inner_note(header, *tags, &block)
      @inner_note << Note.new(header, self, *tags, &block)
    end

    def daily_agenda(date)
      agenda = DailyAgenda.new
      agenda.search(self, date)
      agenda
    end

    def weekly_agenda(date)
      agenda = WeeklyAgenda.new
      agenda.search(self, date)
      agenda
    end

  end

  class Agenda

    attr_accessor :notes

    def initialize(notes = [])
      @notes = notes
    end

    def where(arguments)
      tag_search(arguments[:tag])
        .text_search(arguments[:text])
        .status_search(arguments[:status])
    end

    def tag_search(tag)
      if tag.nil?
        return Agenda.new(@notes)
      end
      notes = @notes.select { |note| note.tags.include? tag }
      Agenda.new notes
    end

    def text_search(text)
      if text.nil?
        return Agenda.new(@notes)
      end
      notes = @notes.select {|note| match_text(note, text) }
      Agenda.new notes
    end

    def match_text(note, text)
      note.header.match(text) or note.body.match(text)
    end

    def status_search(status)
      if status.nil?
        return Agenda.new(@notes)
      end
      notes = @notes.select { |note| note.status == status }
      Agenda.new notes
    end
  end

  class DailyAgenda < Agenda

    def search(file, date)
      @notes = file.notes.select do |note|
        note.scheduled_for_day(date)
      end
    end

  end

  class WeeklyAgenda < Agenda

    def search(file, date)
      @notes = file.notes.select do |note|
        note.scheduled_for_week(date)
      end
    end

  end

  def self.create_file(name, &block)
    File.new(name, &block)
  end
end
