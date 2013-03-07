IMAGE_URLS = %w(
  http://farm3.staticflickr.com/2030/2449885430_193e200881_b_d.jpg
  http://farm3.staticflickr.com/2588/3965047781_608a867df8_b_d.jpg
  http://farm3.staticflickr.com/2377/2462613306_21da7b4313_b_d.jpg
  http://farm4.staticflickr.com/3136/2953142618_e3a264a4c9_b_d.jpg
  http://farm3.staticflickr.com/2659/3849778244_6f43fbb791_z_d.jpg?zz=1
  http://farm4.staticflickr.com/3601/3512124659_4a6f693fdf_d.jpg
  http://farm1.staticflickr.com/169/450003437_e7efa022c7_z_d.jpg?zz=1
  http://farm1.staticflickr.com/55/148634994_4ad0163a40_o_d.jpg
  http://farm6.staticflickr.com/5005/5317722989_67cd89b23e_b_d.jpg
  http://farm8.staticflickr.com/7257/7474187840_150be5905e_b_d.jpg
  http://farm2.staticflickr.com/1234/912643164_4bc1423e77_o_d.jpg
)

namespace :demo do
  task :setup => :environment do
    Bountybase::Metrics.in_background = false
    Deferred.in_background = false
  end
  
  desc "Create demo users"
  task :users => :setup do
    ActiveRecord.as User.admin do
      10.times do 
        name = Faker::Name.name
        email = Faker::Internet.email
        password = email
        Identity::Email.create!(:name => name, :email => email, :password => password, :password_confirmation => password)

        W "created", email
      end
    end
  end
  
  desc "Create demo quests"
  task :quests => :setup do
    ActiveRecord.as User.admin do
      10.times do
        bounty = 10000 * ((r = rand) * r)
        bounty = 0 if bounty < 10

        title = nil
        while !title || title.length > 100
          title = Faker::Lorem.sentence(15)
        end

        quest = Quest.new :bounty => bounty,
          :title => title,
          :description => Faker::Lorem.paragraphs(rand(4) + 1).join("\n")
        
        quest.owner = User.first(:offset => rand(User.count))
        quest.visibility = "public"
        quest.save!

        W title
      end
    end
  end
  
  desc "Create demo criteria"
  task :criteria => :setup do
    count = 0
    ActiveRecord.as User.admin do
      Quest.all.each do |quest|
        next unless quest.criteria.blank?

        0.upto(1 + rand(Quest::NUMBER_OF_CRITERIA-1)) do |idx|
          text = Faker::Lorem.sentence(6)
          description = Faker::Lorem.sentence(12) if rand(3) < 2
          
          quest.send :set_criterium, idx, text, description 
        end
        
        count += 1
        
        quest.save!
      end
      
      W "Added criteria to #{count} quests"
    end
  end
  
  desc "Start some quests"
  task :start => :setup do
    count = 0
    ActiveRecord.as User.admin do
      Quest.pending.each do |quest|
        quest.start!
        count += 1
      end
    end
    
    W "Started #{count} quests"
  end
  
=begin
  desc "Create demo locations"
  task :locations => :setup do
    locations = [ "Berlin, Germany", "Hamburg, Germany", "Germany" ]
    count = 0
    ActiveRecord.as User.admin do
      Quest.all.each do |quest|
        next if rand < 0.7
        count += 1
        
        quest.update_attributes! :location => locations[rand(locations.length)]
      end
      
      W "Added location to #{count} quests"
    end
  end
=end

  desc "Create demo offers"
  task :offers => :setup do
    ActiveRecord.as User.admin do
      users = User.all
      offers = Quest.all.map do |quest|
        next if rand(3) != 0

        next if quest.expired?
        
        unless quest.started?
          quest.duration_in_days = 14
          quest.start!
        end
        offer = Offer.new
        offer.owner = users.at(rand(users.length))
        
        offer.quest = quest
        offer.location = "Hamburg, Germany" if rand(2) == 0
        offer.description = Faker::Lorem.sentence(12) 
        offer.images = [ IMAGE_URLS[rand(IMAGE_URLS.length)] ]
        
        quest.criteria.each_with_index do |criterium, idx|
          quest_criterium = criterium
          offer.send :set_criterium, idx, quest_criterium[:uid], rand(11)
        end
        
        offer.save!
      end.compact
      
      W "Created #{offers.count} offers"
    end
  end
end
