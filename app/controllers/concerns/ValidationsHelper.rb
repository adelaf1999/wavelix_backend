module ValidationsHelper

  def is_positive_integer?(arg)

    # 1, 2, 3, 4

    arg = arg.to_s

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil

      false

    else

      arg = arg.to_i

      arg != 0


    end

  end


  def is_whole_number?(arg)

    # 0, 1, 2, 3

    arg = arg.to_s

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil

      false

    else

      true

    end

  end

end