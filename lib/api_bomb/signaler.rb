class ApiBomb::Signaler
  attr_reader :hold_times, :statuses

  def initialize
    @statuses = []
    @hold_times = []
  end

  def report(fighter)
    @statuses << fighter.value.response.status
    @hold_times << fighter.value.hold_time
  end

  def fighters_lost
    hold_times.count
  end

  def mean_hold_time
    hold_times.mean
  end

  def sd_time
    hold_times.standard_deviation
  end

  def percentile(value)
    hold_times.percentile(value)
  end

  def server_errors
    @statuses.select{|s| s >= 500}.count
  end
end
