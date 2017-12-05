class FooController < ApplicationController
        def show
                render plain: request.base_url 
        end
end
