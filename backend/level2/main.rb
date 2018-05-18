require 'json'
require 'date'

data = File.read('data/input.json')
input = JSON.parse(data)

Car = Struct.new(:id, :price_per_day, :price_per_km) do
  def price_decrease_for_day(day)
    raise Exception.new("`price_decrease_for_day(day)` expects a positive argument, received #{day}") if day < 1
    [1, 1, 0.9, 0.9, 0.9, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.5][day] || 0.5
  end
end

Rental = Struct.new(:id, :car_id, :start_date, :end_date, :distance, :price) do
  def booked_days
    (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
  end
end

car_list = input["cars"].map { |car| Car.new(*car.values) }
rental_list = input["rentals"].map { |rental| Rental.new(*rental.values) }

rental_list.each do |rental|
  car = car_list.select{ |car| car[:id] == rental[:car_id] }.first
  price_per_day_list = (1..rental.booked_days).map { |day| car.price_per_day * car.price_decrease_for_day(day) }
  rental.price = price_per_day_list.inject(:+).to_i + rental.distance * car.price_per_km
end

output = {rentals: rental_list.map{ |r| r.to_h.select{ |k| [:id, :price].include? k }}}

File.open('data/output.json','w') do |f|
  f.write(JSON.pretty_generate(output))
end
