class EarningsController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!


  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized


    else

      @earnings = {}

      @years = Earning.group_by_year(:created_at, format: '%Y', reverse: true).sum(:amount).keys.map &:to_i

      if @years.size > 0

        current_year = DateTime.now.utc.year

        if @years.include?(current_year)

          selected_year = current_year

        else

          selected_year = @years[0]

        end


        @selected_year_index = @years.find_index(selected_year)


        total = 0


        for m in 1..12

          start_day = DateTime.new(selected_year, m, 1)

          end_day = start_day.next_month

          month = Earning.group_by_month(:created_at, range: start_day...end_day, format: "%B %Y").sum(:amount)

          total += month.values[0]


          @earnings[month.keys[0]] = month.values[0]

        end

        @earnings[:total] = total



      end




    end

  end

end
