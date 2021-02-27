class EarningsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def show


    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else


      @earnings = {}

      selected_year = params[:selected_year]

      if is_positive_integer?(selected_year)

        selected_year = selected_year.to_i

        total = 0

        for month in 1..12

          month_earning = get_month_earning(selected_year, month)

          total += month_earning.values[0]

          @earnings[month_earning.keys[0]] = month_earning.values[0]

        end

        @earnings[:total] = total

      end


    end





  end


  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      @earnings = {}

      @years = get_available_years

      if @years.size > 0

        current_year = DateTime.now.utc.year

        if @years.include?(current_year)

          selected_year = current_year

        else

          selected_year = @years[0]

        end


        @selected_year_index = @years.find_index(selected_year)


        total = 0

        for month in 1..12

          month_earning = get_month_earning(selected_year, month)

          total += month_earning.values[0]

          @earnings[month_earning.keys[0]] = month_earning.values[0]

        end

        @earnings[:total] = total

      end


    end

  end


  private


  def get_month_earning(year, month)

    start_day = DateTime.new(year, month, 1)

    end_day = start_day.next_month

    Earning.group_by_month(:created_at, range: start_day...end_day, format: "%B %Y").sum(:amount)

  end

  def get_available_years

    Earning.group_by_year(:created_at, format: '%Y', reverse: true).sum(:amount).keys.map &:to_i

  end




end
