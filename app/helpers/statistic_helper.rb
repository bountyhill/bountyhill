module StatisticHelper
  
  def distance_of_time_in_days_to_now(time)
    now = Time.now
    distance =  if now > time then  (now - time)
                else                (time - now)
                end.round
    distance / 60 / 60 / 24
  end
end
