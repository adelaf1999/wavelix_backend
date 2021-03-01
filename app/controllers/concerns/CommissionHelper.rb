module CommissionHelper


  def calculate_our_earning_store(net_amount)

    if net_amount <= 10

      net_amount * 0.15

    elsif net_amount > 10 && net_amount <= 70

      net_amount * 0.1

    elsif net_amount > 70 && net_amount <= 700

      net_amount * 0.05

    else

      net_amount * 0.03

    end


  end

  def calculate_our_earning_driver(net_amount)

    if net_amount <= 10

      net_amount * 0.25

    elsif net_amount > 10 && net_amount <= 100

      net_amount * 0.15

    else

      net_amount * 0.1

    end

  end




end