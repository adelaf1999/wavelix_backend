module CommissionHelper


  def calculate_our_earning_store(net_amount)


    if net_amount <= 10

      net_amount * 0.2

    elsif net_amount > 10 && net_amount <= 40

      net_amount * 0.13

    elsif net_amount > 40 && net_amount <= 70

      net_amount * 0.08

    else

      net_amount * 0.03

    end


  end

  def calculate_our_earning_driver(net_amount)

    if net_amount <= 10

      net_amount * 0.2

    elsif net_amount > 10 && net_amount <= 40

      net_amount * 0.15

    elsif net_amount > 40 && net_amount <= 80

      net_amount * 0.08

    else

      net_amount * 0.05

    end

  end




end