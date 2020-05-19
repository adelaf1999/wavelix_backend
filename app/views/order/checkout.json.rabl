if @success != nil
    node(:success) { @success  }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @product != nil
    node(:product) { @product }
end

if @order != nil
    node(:order) { @order }
end

if @product_options != nil

    node(:product_options) { @product_options }

end