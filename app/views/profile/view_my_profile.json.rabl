if @profile_data != nil
    node(:profile_data) { @profile_data  }
end

if @profile_blocked != nil
    node(:profile_blocked) { @profile_blocked  }
end