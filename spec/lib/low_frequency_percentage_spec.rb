require 'spec_helper'

describe 'low_frequency_percentage' do

  let(:user) { FactoryGirl.build(:user) }
  let(:localities) {
    n = 10
    the_localities = Array.new(n)
    j = 0
    until j > n do
      name = "locality" + (j+1).to_s
      the_localities[j]=Locality.create(name: name)
      j=j+1
    end
    the_localities
  }

  it 'Given current user with total sum freq less than the sum threshold(300), is_infrequent, returns false' do
    user.frequencies.build(locality_id: localities[0].id, value: 100)
    user.frequencies.build(locality_id: localities[1].id, value: 100)
    user.frequencies.build(locality_id: localities[2].id, value: 70)

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_sum_threshold(300)
    result = low_frequency.is_infrequent?(nil)

    expect(result).to be_false
  end

  it 'Given current user with total sum freq less than the sum threshold(100), is_infrequent, returns false' do
    user.frequencies.build(locality_id: localities[0].id, value: 80)
    user.frequencies.build(locality_id: localities[1].id, value: 18)
    user.frequencies.build(locality_id: localities[2].id, value: 1)
    user.save

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_sum_threshold(100)
    result = low_frequency.is_infrequent?(nil)

    expect(result).to be_false
  end

  it 'Given current user with total visited localties less than the quantity threshold(5), is_infrequent, returns false' do
    user.frequencies.build(locality_id: localities[0].id, value: 100)
    user.frequencies.build(locality_id: localities[1].id, value: 100)
    user.frequencies.build(locality_id: localities[2].id, value: 330)
    user.save

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_quantity_threshold(5)
    result = low_frequency.is_infrequent?(nil)

    expect(result).to be_false
  end

  it 'Given current user with total visited localties less than the quantity threshold(6), is_infrequent, returns false' do
    user.frequencies.build(locality_id: localities[0].id, value: 100)
    user.frequencies.build(locality_id: localities[1].id, value: 100)
    user.frequencies.build(locality_id: localities[2].id, value: 330)
    user.frequencies.build(locality_id: localities[3].id, value: 330)
    user.frequencies.build(locality_id: localities[4].id, value: 330)
    user.save

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_quantity_threshold(6)
    result = low_frequency.is_infrequent?(nil)

    expect(result).to be_false
  end

  it 'Given current user with frequency percentage < epsilon is_infrequent, returns true' do
    user.frequencies.build(locality_id: localities[0].id, value: 100)
    user.frequencies.build(locality_id: localities[1].id, value: 100)
    user.frequencies.build(locality_id: localities[2].id, value: 100)
    user.frequencies.build(locality_id: localities[3].id, value: 1)
    user.save

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_sum_threshold(300)
    low_frequency.set_quantity_threshold(4)
    result = low_frequency.is_infrequent?(localities[3])

    expect(result).to be_true
  end

  it 'Given current user with frequency percentage > epsilon is_infrequent, returns false' do
    user.frequencies.build(locality_id: localities[0].id, value: 100)
    user.frequencies.build(locality_id: localities[1].id, value: 100)
    user.frequencies.build(locality_id: localities[2].id, value: 100)
    user.frequencies.build(locality_id: localities[3].id, value: 4)
    user.save

    low_frequency = LowFrequencyPercentage.new(user)
    low_frequency.set_sum_threshold(300)
    low_frequency.set_quantity_threshold(4)
    result = low_frequency.is_infrequent?(localities[3])

    expect(result).to be_false
  end
end