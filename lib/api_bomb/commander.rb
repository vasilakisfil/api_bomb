class ApiBomb::Commander
  include ApiBomb::Strategies::Naive

  attr_reader :army, :fronts, :duration, :signaler, :logger

  def initialize(army:, fronts: 1, duration: 10, logger: Logger.new(STDOUT))
    @duration = duration
    @army = army
    @fighters = []
    @statuses = []
    @hold_times = []
    @fronts = fronts
    @logger = logger
  end

  def start_attack!
    begin
      #I know that Timeout is really bad
      #but literarly there is no other generic way doing this
      #Fortunately we only do requests to an API so it shouldn't affect us
      Timeout::timeout(duration) {
        attack
      }
    rescue Timeout::Error
    end

    report_attack_result
  end

private
  def report_attack_result
    log = ''
    log += "Elapsed time: #{attack_result[:duration]}\n"
    log += "Concurrency: #{attack_result[:fronts]} threads\n"
    log += "Number of requests: #{attack_result[:requests]}\n"
    log += "Requests per second: #{attack_result[:rps]}\n"
    log += "Requests per minute: #{attack_result[:rpm]}\n"
    log += "Average response time: #{attack_result[:average_rt]}\n"
    log += "Standard deviation: #{attack_result[:sd_rq_time]}\n"
    log += "Percentile 90th: #{attack_result[:percentile_90]}\n"
    log += "Percentile 95th: #{attack_result[:percentile_95]}\n"
    log += "Percentile 99th: #{attack_result[:percentile_99]}\n"
    log += "server errors (5xx statuses): #{attack_result[:server_errors]}\n"

    @logger.info(log)
  end

  def attack_result
    {
      duration: duration,
      fronts: @fronts,
      requests: @signaler.fighters_lost,
      rps: @signaler.fighters_lost / duration,
      rpm: @signaler.fighters_lost / (duration/60.0),
      average_rt: @signaler.mean_hold_time,
      sd_rq_time: @signaler.sd_time,
      percentile_90: @signaler.percentile(90),
      percentile_95: @signaler.percentile(95),
      percentile_99: @signaler.percentile(99),
      server_errors: @signaler.server_errors
    }
  end

  def signaler
    @signaler ||= ApiBomb::Signaler.new
  end
end
