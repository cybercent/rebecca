require 'json'
require 'date'

data = File.read('data/input.json')
input = JSON.parse(data)

COMMISSION_PERCENTAGE = 0.3

ASSISTANCE_PRICE = 100
GPS_PRICE = 500
BABY_SEAT_PRICE = 200
ADDITIONAL_INSURANCE_PRICE = 1000


Car = Struct.new(:id, :price_per_day, :price_per_km) do
  def price_decrease_for_day(day)
    raise Exception.new("`price_decrease_for_day(day)` expects a positive argument, received #{day}") if day < 1
    [1, 1, 0.9, 0.9, 0.9, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.5][day] || 0.5
  end
end

Option = Struct.new(:id, :rental_id, :type)

class Rental

  attr_accessor :id, :car_id, :start_date, :end_date, :distance, :car, :options
  attr_reader :commission, :actions

  Commission = Struct.new(:insurance_fee, :assistance_fee, :drivy_fee)
  Action = Struct.new(:who, :type, :amount)

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

  def options_price
    total  = 0

    total += (GPS_PRICE * booked_days) if options.include?("gps")
    total += (BABY_SEAT_PRICE * booked_days) if options.include?("baby_seat")

    total
  end

  def additional_insurance_price
    options.include?("additional_insurance") ? (ADDITIONAL_INSURANCE_PRICE * booked_days) : 0
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
    booked_days * ASSISTANCE_PRICE
  end

  def drivy_fee
    (price_commission - insurance_fee - assistance_fee).to_i
  end

  def commission
    Commission.new(insurance_fee, assistance_fee, drivy_fee).to_h
  end

  def owner_fee
    (price - price_commission).to_i
  end

  def actions
    [ Action.new("driver", "debit", price + options_price + additional_insurance_price),
      Action.new("owner", "credit", owner_fee + options_price),
      Action.new("insurance", "credit", insurance_fee),
      Action.new("assistance", "credit", assistance_fee),
      Action.new("drivy", "credit", drivy_fee + additional_insurance_price) ].map(&:to_h)
  end
end


car_list = input["cars"].map { |car| Car.new(*car.values) }
rental_list = input["rentals"].map { |rental| Rental.new(*rental.values) }
option_list = input["options"].map { |option| Option.new(*option.values) }

rental_list.each do |rental|
  rental.car = car_list.select{ |car| car[:id] == rental.car_id }.first
  rental.options = option_list.select { |option| option[:rental_id] == rental.id }.map(&:type)
end

output = {rentals: rental_list.map{ |r| {id: r.id, options: r.options, actions: r.actions} }}

File.open('data/output.json','w') do |f|
  f.write(JSON.pretty_generate(output))
end
