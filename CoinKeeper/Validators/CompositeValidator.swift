//
//  CompositeValidator.swift
//  ValidatorDemo
//
//  Created by BJ Miller on 5/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

class CompositeValidator<T>: ValidatorType<T> {
  let validators: [ValidatorType<T>]

  init(validators: [ValidatorType<T>]) {
    self.validators = validators
  }

  override func validate(value: T) throws {
    for validator in validators {
      try validator.validate(value: value)
    }
  }
}
