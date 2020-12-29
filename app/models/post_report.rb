class PostReport < ApplicationRecord

  belongs_to :post_case

  enum report_type: {
      copyright_violation: 0,
      sexual_content: 1,
      violent_content: 2,
      hateful_speech: 3,
      harmful_acts: 4,
      child_abuse: 5,
      promotes_terrorism: 6,
      spam: 7
  }

end
