class Mugshots
	def initialize(win)
		@sheet = Gosu::Image::load_tiles(win,"sprites/mmzmugs.gif",-6,-3,true)
	end
	
	def [](who)
		case who
			when :Zero
				@sheet[0]
			when :Ciel
				@sheet[1]
			when :Alouette
				@sheet[11]
			else
				@sheet[who]
		end
	end
	
end

module Dialogs

	class Fadeout
		def initialize(win)
			@win = win
			@img = Gosu::Image.new(win,"media/Earth.png",false)
			@color = Gosu::Color::BLACK
			@color.alpha = 5
			@mode = :out
		end
		
		def update
			if @mode == :out
				@color.alpha += 5 
				@mode = :in if @color.alpha == 255
			else
				@color.alpha -= 5
			end
		end
		
		def is_done?
			return (@color.alpha == 0)
		end
		
		def ready?
			return (@color.alpha > 250)
		end
		
		def draw
			@img.draw(0,0,ZIndex::UI,50,50,@color)
		end

	end
	
	class PopupBox
		def initialize(win,x,y,text="",portrait = nil)
			@x,@y = x,y
			@textbg = Gosu::Image.new(win,"sprites/textbox.png",true)
			@scale_x = 0.75
			@scale_y = 0.5
			if portrait
				@scale_x += (portrait.width.to_f / @textbg.width.to_f)/2.0
			end
			@line_image = Gosu::Image::from_text(win,text,Gosu::default_font_name,36, 5, ((@textbg.width-10)*@scale_x).to_i, :left)
			@max_lines = (@line_image.height / (@textbg.height*@scale_y).to_i).to_i() +1
			@current_line = 0
			@clip_to = win.method(:clip_to)
			@port = portrait
		end
		
		def update
		end
		
		def draw
			@textbg.draw(@x,@y,3, @scale_x,@scale_y)
			off_x = 5
			if @port then @port.draw(@x+off_x,@y+off_x,3); off_x += @port.width end
			@clip_to.call(@x+off_x,@y+5,(@textbg.width-5)*(3*@scale_x/4),(@textbg.height-15)*@scale_y) {
				@line_image.draw(@x+off_x,@y+5-(@current_line*((@textbg.height-9)*@scale_y).to_i),3)
			}
		end
			
		def advance
			@current_line += 1
		end
		
		def ok
			self.advance
		end
		
		def cancel
			self.advance
		end
		
		def is_done?
			@current_line >= @max_lines
		end
	end
	
	#predefine the important dialogs
	if ARGV.index("-jp")
		MissionOneStartText = "ここは？　　　　　　　　　　　　　　　シエロ、返事して。転送してくれ。　　　　シエロ？　　　　　　　　　　　　　　　　　　　　反応なし。自分で逃げないと"	
		MissionOneCompleteText = "それは最後。これで逃げるはず"
		MissionTwoStartText = "また妙な空間。くだらない"
		MissionTwoCompleteText = "。。。"
		MissionThreeLoopText = "。。。面倒臭い"
	else
		MissionOneStartText = "...Where am I?                       Base, come in. Transfer me out...  Base?                              No response. I'll have to find my own way out.                           Can't transfer out on my own. Maybe these crystals are of some use...";
		MissionOneCompleteText = "That's the last of them. With this I should be able to get out of here."
		MissionTwoStartText = "Another strange realm. This is ridiculous."
		MissionTwoCompleteText = "Please let this work..."
		MissionThreeLoopText = "Oh bother."
	end
end

class DeathExplosion
	attr_reader :speed, :cutoff, :count
	@@count = 0
	@@dist = []
	@@speed = []
	@@cutoff = 32
	def initialize(win,x,y)
		@img = Gosu::Image::load_tiles(win,"sprites/zero_explode.png",32,32,true)
		@x,@y = x,y
		@active = true
		self.new_explosion
	end

	def new_explosion
		@@dist[@@count] = 0
		@@speed[@@count] = 0.25
		@@count += 1
		puts "New explosion: dist = #{@@dist[@@count - 1]} speed = #{@@speed[@@count - 1]}, total: #{@@count}"
	end
	
	def update
		return unless @active
		0.upto(@@count - 1) { |c|
			@@dist[c] += @@speed[c]
			@@speed[c] += 0.06 
		}
		if @@dist[0] > @@cutoff and @@count < 2
			self.new_explosion
		end
	end
		
	def draw
		0.upto(@@count - 1) { |c|
			[*0..8].each { |a|
				@img[Gosu::milliseconds / 75 % @img.size].draw(@x+Gosu::offset_x(a*45,@@dist[c]),@y+Gosu::offset_y(a*45,@@dist[c]),ZIndex::Player)
			}
		}
	end
	
	def is_done?
		if @@dist[@@count - 1] >= 650
			@@dist = []
			@@speed = []
			@@count = 0
			@active = false
			return true
		end
		return false
	end
end

class GameEvent
	attr_reader :running
	def initialize()
		@events = []
		@results = []
		@running = true
	end

	def addAction(&block)
		@action = block
	end

	def fire
		@action.call
	end

	def addTrigger(&cond)
		@events.push(cond)
		@results.push(false)
	end

	def draw
	end

	def update
		return unless @running
		#check for advancement
		0.upto(@events.length-1) { |i|
			#puts "#{self} checking #{@events[i]} ? " + @events[i].call.to_s
			@results[i] = @events[i].call
		}
	end

	def is_done?
		#puts "checking if #{self} is done ? "+ (@results.index(false) == nil).to_s
		@running = false if @results.index(false) == nil
		!@running
	end

	def reset
		@running = true
	end
	
end

class EndlessEvent < GameEvent
	def update
		0.upto(@events.length-1) { |i|
			@results[i] = (@events[i][0] == @events[i][1])
		}	
	end
	
	def is_done?
		@results.find(false) == nil
	end
end