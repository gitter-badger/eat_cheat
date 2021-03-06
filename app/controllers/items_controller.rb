class ItemsController < ApplicationController
  before_filter :authenticate_user! 

  def show
  end

  def new

    @new_profile = current_user.profiles
    @data = @new_profile.last
    
    if @data != nil 
      if (@data.gender.to_i == 2)
          @cal_need = ((655 + (4.3 * @data.weight.to_i) + (4.7 * @data.height.to_i) - (4.7 * @data.age.to_i)) * @data.activity_level.to_i)
        elsif (@data.gender == 1)
          @cal_need = ((66 +(6.3 * @data.weight.to_i) + (12.9 * @data.height.to_i) - (6.8 * @data.age.to_i))  * @data.activity_level.to_i)
      end
    else  @cal_need = 2000
    end


    @item = Item.new
    #gets response
    query = params[:q]

    unless query.nil? 
      #makes the query into an array
      query_arr = query.split(' ')

      #create an empty string
      search = ""

      #adds the first thing in the array to the string
      search << query_arr[0]

      #if array is bigger than just one word, runs through the rest and adds those as well
      if query_arr.length > 1 
        count = query_arr.length - 1
        index = 1
       
        count.times do
          search << "+#{query_arr[index]}"
          index += 1
        end
      end
    end
    

    parse = "fields=item_name%2Cbrand_name%2Citem_id%2Cnf_calories%2Cnf_total_fat%2Cnf_protein%2Cnf_total_carbohydrate%2Cnf_serving_weight_grams&appId=58809d9f&appKey=f0ee2e843b2e4a910d564ccebfc2c1dd" 

    if search 
        resp = Typhoeus.get("https://api.nutritionix.com/v1_1/search/#{search}", params: parse)
        @items = JSON.parse(resp.body)['hits']
        # render json: @items
        puts "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n #{@items}"
    else
        @items = []
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @items }
    end


  end

  def create
    @item = Item.new(item_params)

    # turn fat carbs and protein into calories, not grams
    @item.fat *= 9
    @item.protein *= 4
    @item.carbs *= 4

    # check that item name is displayed correctly
    name = @item.name.split('+').join(' ')
    name2 = name.split('%2C').join(', ')

    if (name.length == 1)
      @item.name = name2[0]
    else
      @item.name = name2
    end

    puts "\n\n\n\n\n\n\n\n\n\n\n\n\n #{@item.name}"

    if @item.save 
      current_user.items << @item
    end

    respond_to do |format|
      format.html
      format.json {
        if @item.save 
          current_user.items << @item
        end
      }
    end
  end

  def index
    @items = current_user.items.all

    respond_to do |format|
      format.html
      format.json { render json: @items}
    end
  end

  def destroy
  end

  private
  def item_params
    params.require(:item).permit(:nutritionix_id, :calories, :fat, :protein, :carbs, :serving_weight_grams, :name)
  end



end
