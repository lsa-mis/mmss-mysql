ActiveAdmin.register Demographic do
  menu parent: 'Camp Setup'

  config.filters = false

  permit_params :name, :description, :protected


  controller do
    def scoped_collection
      Demographic.modifiable
    end
  end
end
