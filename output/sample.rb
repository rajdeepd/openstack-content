require "rubygems"
require "sinatra"
require "newrelic_rpm"

get "/" do
  redirect("/openstack.html")

end

get "/tags" do
  redirect "/tags/tags.html"
end
