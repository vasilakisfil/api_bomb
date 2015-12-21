class ApiBomb::Commander
  include ApiBomb::Strategy::Naive

  attr_reader :army, :fronts, :duration, :signaler, :logger, :requests

  def initialize(army:, fronts: 1, duration: 10, logger: Logger.new(STDOUT), requests: nil)
    @duration = duration
    @army = army
    @fighters = []
    @statuses = []
    @hold_times = []
    @fronts = fronts
    @logger = logger
    @requests = requests
  end

  def start_attack!
    begin
      #I know that Timeout is really bad
      #but literarly there is no other generic way doing this
      #Fortunately we only do requests to an API so it shouldn't affect us
      logger.info "Starts firing requests"
      Timeout::timeout(duration) {
        attack
      }
    rescue Timeout::Error
      logger.info "Ceasefire!"
    end

    report_attack_result
  end

private
  def report_attack_result
    logger.info "Elapsed time: #{attack_result[:duration]}"
    logger.info "Concurrency: #{attack_result[:fronts]} threads"
    logger.info "Number of requests: #{attack_result[:requests]}"
    logger.info "Requests per second: #{attack_result[:rps]}"
    logger.info "Requests per minute: #{attack_result[:rpm]}"
    logger.info "Average response time: #{attack_result[:average_rt]}"
    logger.info "Standard deviation: #{attack_result[:sd_rq_time]}"
    logger.info "Percentile 50th: #{attack_result[:percentile_50]}"
    logger.info "Percentile 90th: #{attack_result[:percentile_90]}"
    logger.info "Percentile 95th: #{attack_result[:percentile_95]}"
    logger.info "Percentile 99th: #{attack_result[:percentile_99]}"
    logger.info "Server status stats: #{attack_result[:server_status_stats]}"
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
      percentile_50: @signaler.percentile(50),
      percentile_90: @signaler.percentile(90),
      percentile_95: @signaler.percentile(95),
      percentile_99: @signaler.percentile(99),
      server_status_stats: @signaler.server_status_stats
    }
  end

  def signaler
    @signaler ||= ApiBomb::Signaler.new
  end
end
