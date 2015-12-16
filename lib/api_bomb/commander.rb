class ApiBomb::Commander
  include ApiBomb::Strategies::Naive

  attr_reader :army, :fronts, :duration, :signaler

  def initialize(army:, fronts: 1, duration: 10)
    @duration = duration
    @army = army
    @fighters = []
    @statuses = []
    @hold_times = []
    @fronts = fronts
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
    puts "Elapsed time: #{attack_result[:duration]}"
    puts "Concurrency: #{attack_result[:fronts]} threads"
    puts "Number of requests: #{attack_result[:requests]}"
    puts "Requests per second: #{attack_result[:rps]}"
    puts "Requests per minute: #{attack_result[:rpm]}"
    puts "Average response time: #{attack_result[:average_rt]}"
    puts "Standard deviation: #{attack_result[:sd_rq_time]}"
    puts "Percentile 90th: #{attack_result[:percentile_90]}"
    puts "Percentile 95th: #{attack_result[:percentile_95]}"
    puts "Percentile 99th: #{attack_result[:percentile_99]}"
    puts "server errors (5xx statuses): #{attack_result[:server_errors]}"
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
