require 'json'
require 'date'

data = File.read('data/input.json')
input = JSON.parse(data)

COMMISSION_PERCENTAGE = 0.3

Car = Struct.new(:id, :price_per_day, :price_per_km) do
  def price_decrease_for_day(day)
    raise Exception.new("`price_decrease_for_day(day)` expects a positive argument, received #{day}") if day < 1
    [1, 1, 0.9, 0.9, 0.9, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.5][day] || 0.5
  end
end


class Rental

  attr_accessor :id, :car_id, :start_date, :end_date, :distance, :car
  attr_reader :commission

  Commission = Struct.new(:insurance_fee, :assistance_fee, :drivy_fee)

  def initialize(id, car_id, start_date, end_date, distance)
    @id = id
    @car_id = car_id
    @start_date = start_date
    @end_date = end_date
    @distance = distance
  end

  def booked_days
    (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
  end

  def price
    (1..booked_days).map { |day|
      car.price_per_day * car.price_decrease_for_day(day)
    }.inject(:+).to_i + distance * car.price_per_km
  end

  def price_commission
    price * COMMISSION_PERCENTAGE
  end

  def insurance_fee
    (price_commission / 2).to_i
  end

  def assistance_fee
    booked_days * 100
  end

  def drivy_fee
    (price_commission - insurance_fee - assistance_fee).to_i
  end

  def commission
    Commission.new(insurance_fee, assistance_fee, drivy_fee).to_h
  end
end


car_list = input["cars"].map { |car| Car.new(*car.values) }
rental_list = input["rentals"].map { |rental| Rental.new(*rental.values) }

rental_list.each do |rental|
  rental.car = car_list.select{ |car| car[:id] == rental.car_id }.first
end

output = {rentals: rental_list.map{ |r| {id: r.id, price: r.price, commission: r.commission} }}

File.open('data/output.json','w') do |f|
  f.write(JSON.pretty_generate(output))
end
