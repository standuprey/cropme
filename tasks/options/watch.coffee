module.exports =
  coffee:
    files: ["scripts/{,*/}*.{coffee,litcoffee,coffee.md}"]
    tasks: ["coffee:dist"]

  coffeeTest:
    files: ["test/spec/{,*/}*.{coffee,litcoffee,coffee.md}"]
    tasks: [
      "coffee:test"
      "test"
    ]