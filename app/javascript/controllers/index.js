import { Application } from "@hotwired/stimulus"

const application = Application.start()

const context = require.context(".", true, /_controller\.js$/)
context.keys().forEach((filename) => {
  const controllerModule = context(filename)
  const controllerName = filename
    .replace(/^.\//, '') // Remove leading './'
    .replace(/_controller\.js$/, '') // Remove trailing '_controller.js'
    .replace(/\//g, "--") // Replace nested directories with '--'
    .replace(/_/g, "-") // Replace underscores with dashes

  application.register(controllerName, controllerModule.default)
  // console.log(`Registering controller: ${controllerName}`)

})