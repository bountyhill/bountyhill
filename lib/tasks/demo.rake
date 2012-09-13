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
  task :setup => :environment
  
  task :users => :setup do
    10.times do 
      name = Faker::Name.name
      email = Faker::Internet.email
      password = email
      Identity::Email.create!(:name => name, :email => email, :password => password, :password_confirmation => password)
    
      W "created", email
    end
  end
  
  task :quests => :setup do
    10.times do
      bounty = 10000 * ((r = rand) * r)
      bounty = 0 if bounty < 10

      title = nil
      while !title || title.length > 100
        title = Faker::Lorem.sentence(15)
      end
      
      quest = Quest.new :bounty => bounty,
        :title => title,
        :description => Faker::Lorem.paragraphs(rand(4) + 1).join("\n"),
        :image_url =>  IMAGE_URLS[rand(IMAGE_URLS.length)]

      quest.owner = User.first(:offset => rand(User.count))
      quest.visibility = "public"
      quest.save!

      W title
    end
  end
end