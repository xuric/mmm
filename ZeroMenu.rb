# module CyberElf
	# def CyberElf.init(win)
		# @@sheet = Gosu::Image.new(win,"sprites/z123cyberelves.gif",false)
		# @red = []
		# @red.push(Gosu::Image.new(win,@@sheet,false,3,1,16,16))
		# @red.push(Gosu::Image.new(win,@@sheet,false,22,1,16,16))
		# @red.push(Gosu::Image.new(win,@@sheet,false,40,1,16,16))
		# @red.push(Gosu::Image.new(win,@@sheet,false,55,1,16,16))
		# @red_sparkle = []
		# @red_sparkle.push(Gosu::Image.new(win,@@sheet,false,74,6,7,7))
		# @red_sparkle.push(Gosu::Image.new(win,@@sheet,false,80,6,7,7))
		# @red_sparkle.push(Gosu::Image.new(win,@@sheet,false,87,6,7,7))
		# @red_sparkle.push(Gosu::Image.new(win,@@sheet,false,95,6,7,7))
		# @red_sparkles = []
		
		# @green = []
		# @green.push(Gosu::Image.new(win,@@sheet,false,3,20,16,16))
		# @green.push(Gosu::Image.new(win,@@sheet,false,22,20,16,16))
		# @green.push(Gosu::Image.new(win,@@sheet,false,40,20,16,16))
		# @green_sparkle = []
		# @green_sparkle.push(Gosu::Image.new(win,@@sheet,false,74,24,7,7))
		# @green_sparkle.push(Gosu::Image.new(win,@@sheet,false,80,24,7,7))
		# @green_sparkle.push(Gosu::Image.new(win,@@sheet,false,87,24,7,7))
		# @green_sparkle.push(Gosu::Image.new(win,@@sheet,false,95,24,7,7))
		# @green_sparkles = []
		
		# @blue = []
		# @blue.push(Gosu::Image.new(win,@@sheet,false,3,38,16,16))
		# @blue.push(Gosu::Image.new(win,@@sheet,false,22,38,16,16))
		# @blue.push(Gosu::Image.new(win,@@sheet,false,40,38,16,16))
		# @blue.push(Gosu::Image.new(win,@@sheet,false,55,38,16,16))
		# @blue_sparkle = []
		# @blue_sparkle.push(Gosu::Image.new(win,@@sheet,false,74,42,7,7))
		# @blue_sparkle.push(Gosu::Image.new(win,@@sheet,false,80,42,7,7))
		# @blue_sparkle.push(Gosu::Image.new(win,@@sheet,false,87,42,7,7))
		# @blue_sparkle.push(Gosu::Image.new(win,@@sheet,false,95,42,7,7))
		# @blue_sparkles = []
	# end
	
	# def CyberElf.draw(which,x,y)
		# x += Math::cos(Gosu::milliseconds/325)*1.25
		# y += Math::sin(2*Gosu::milliseconds/325)*1.25
		# case which
			# when :red
				# unless @red_sparkles.length == 0
					# @red_sparkles.reject! { |s|
						# if s[:oy] >= 7
							# true
						# else
							# s[:oy] += 1/5.0
							# s[:s] += 1 if Gosu::milliseconds/160 % @red_sparkle.length == 0
							# s[:s] %= @red_sparkle.length
							# false
						# end
						
					# }
				# end
				# if @red_sparkles.length < 4 and rand(100) < 15
					# @red_sparkles.push({:x=>x+rand(@red[0].width),:y=>y+@red[0].height,:oy=>0,:s=>rand(@red_sparkle.length)})
				# end
				# @red[Gosu::milliseconds/160 % @red.size].draw(x,y,ZIndex::Mobiles)
				# @red_sparkles.each { |s|
					# @red_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				# }
			# when :blue
				# unless @blue_sparkles.length == 0
					# @blue_sparkles.reject! { |s|
						# if s[:oy] >= 7
							# true
						# else
							# s[:oy] += 1/5.0
							# s[:s] += 1 if Gosu::milliseconds/160 % @blue_sparkle.length == 0
							# s[:s] %= @blue_sparkle.length
							# false
						# end
						
					# }
				# end
				# if @blue_sparkles.length < 4 and rand(100) < 15
					# @blue_sparkles.push({:x=>x+rand(@blue[0].width),:y=>y+@blue[0].height,:oy=>0,:s=>rand(@blue_sparkle.length)})
				# end
				# @blue[Gosu::milliseconds/160 % @blue.size].draw(x,y,ZIndex::Mobiles)
				# @blue_sparkles.each { |s|
					# @blue_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				# }
			# when :green
				# unless @green_sparkles.length == 0
					# @green_sparkles.reject! { |s|
						# if s[:oy] >= 7
							# true
						# else
							# s[:oy] += 1/5.0
							# s[:s] += 1 if Gosu::milliseconds/160 % @green_sparkle.length == 0
							# s[:s] %= @green_sparkle.length
							# false
						# end
						
					# }
				# end
				# if @green_sparkles.length < 4 and rand(100) < 15
					# @green_sparkles.push({:x=>x+rand(@green[0].width),:y=>y+@green[0].height,:oy=>0,:s=>rand(@green_sparkle.length)})
				# end
				# @green[Gosu::milliseconds/160 % @green.size].draw(x,y,ZIndex::Mobiles)
				# @green_sparkles.each { |s|
					# @green_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				# }
		# end
	# end
	
	# def CyberElf.[](s)
		# case s
			# when :red
				# @red[Gosu::milliseconds/160 % @red.size]
			# when :blue
				# @blue[Gosu::milliseconds/160 % @blue.size]
			# when :green
				# @green[Gosu::milliseconds/160 % @green.size]
		# end
	# end
# end

class Selector
	def initialize(win)
		@win = win
		@x = @y = 0
		sheet = Gosu::Image.new(win,"sprites/z123cyberelves.gif",false)
		@selector = [Gosu::Image.new(win,sheet,false,3,1,16,16),
		             Gosu::Image.new(win,sheet,false,22,1,16,16),
		             Gosu::Image.new(win,sheet,false,40,1,16,16),
		             Gosu::Image.new(win,sheet,false,55,1,16,16)]
		@sparkle = Gosu::Image::load_tiles(win,Gosu::Image.new(win,sheet,false,74,6,7*4,7),7,7,false)
		@sparkles = []
		@target = nil
		@src = [@x,@y]
		@move_speed = 2.5
	end
	
	def setloc(x,y)
		@x,@y = x,y
	end
	
	def getloc
		if @target
			return @src
		else
			return [@x,@y]
		end
	end
	
	def moveto(x,y)
		@target = [x,y]
		@move_speed = Gosu::distance(@x,@y,*@target) / 9.0
	end
	
	def snap
		if @target
			@x,@y = *@target
			@target = nil
		end
	end
	
	def reset
		@sparkles = []
	end
	
	def draw(scale=1.0,color=Gosu::Color::WHITE)
		#move closer to target
		if @target
			if Gosu::distance(@x,@y,*@target) < @move_speed or @move_speed < 0.9
				@x,@y = *@target
				@src = @target
				@target = nil
			else
				theta = Gosu::angle(@x,@y,*@target)
				@x += Gosu::offset_x(theta,@move_speed)
				@y += Gosu::offset_y(theta,@move_speed)
			end
		end
		x = @x + Math::cos(Gosu::milliseconds/325)*1.25
		y = @y + Math::sin(2*Gosu::milliseconds/325)*1.25
		unless @sparkles.length == 0
			@sparkles.reject! { |s|
				if s[:oy] >= 7
					true
				else
					s[:oy] += 1/5.0
					s[:s] += 1 if Gosu::milliseconds/160 % @sparkle.length == 0
					s[:s] %= @sparkle.length
					false
				end
			}
		end
		if @sparkles.length < 4 and rand(100) < 15
			@sparkles.push({:x=>x+7+rand(@selector[0].width),:y=>y+@selector[0].height,:oy=>0,:s=>rand(@sparkle.length)})
		end
		
		@selector[Gosu::milliseconds/160 % @selector.size].draw(x,y,ZIndex::UI,1.0,1.0,color)
		@sparkles.each { |s|
			@sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::UI,1.0,1.0,color)
		}
	end
	
	def ready?
		return (@target == nil)
	end
end

class BoxSelector < Selector
	def initialize(win)
		super(win)
		@selector = Gosu::Image::load_tiles(win,"sprites/selectorbox.png",-6,-1,false)
	end
	
	def draw(scale=1.2,color=Gosu::Color::WHITE)
		@selector[Gosu::milliseconds/66 % @selector.size].draw(@x,@y,ZIndex::UI,scale,scale,color)
	end
	
	def ready?
		puts "is x:#{@x},y:#{@y} ok?"
		true
	end
end

class Menu
	attr_accessor :selector
	def initialize(win,title)
		@win = win
		@bg = Gosu::Image.new(win,"sprites/textbox.png",true)
		@title = title
		@@title_font = Gosu::Font.new(win,"Stencil",15)
		#@title = Gosu::Image::from_text(win,title, "Stencil",15,1,title.length*11,:left)
		#puts "#{self.class}::title=#{title} -> #{@title.width},#{@title.height}"
		#@selector = win.Selector
		@@selector = Selector.new(win)
		#@@selector = BoxSelector.new(win)
		@lastloc = []
		@dur = 9.0 #updates before done fading/sizing = 0.15s
		@op = 0
		@fade_speed = (255.0 / @dur)
		@scale = 0.0
		@grow_speed = (1.00 / @dur) 
		@fade = nil
		@stop = 255 #just in case
		@selected_index = 0
		@active = false

	end
	
	def set_options(*opt_list)
		@opt_names = []
		@options = []
		opt_list.each { |o|
				@opt_names.push o
				@options.push(Gosu::Image::from_text(@win,o.to_s, Gosu::default_font_name,25,1, @bg.width-10,:left))
		}
	end
	
	def next
		self.move_selector 1
	end
	
	def prev
		self.move_selector -1
	end

	def move_selector(offs)
		@selected_index = (@selected_index+offs) % @options.size
		y = 0
		0.upto(@selected_index) { |i| y += @options[i].height }
		@@selector.moveto(@x+7,@y+y)
	end
	
	
	def fadein
		@fade = :in
		@op += @fade_speed
		@stop = 255
		@active = true
		@lastloc.push @@selector.getloc
		begin
			#was .setloc
			@@selector.moveto(@x+7,@y+(27*(@selected_index+1)))
		rescue TypeError => e
			puts "#{e.message}"
		end
	end
	
	def fadeout
		@fade = :out
		@stop = 0
	end
	
	def clear
		self.reset
		@op = 0
		@scale = 0.0
		@@selector.reset
		@@selector.moveto(*@lastloc.pop) if @lastloc.length > 0
	end
		
	def reset
		@fade = nil
		@stop = 255
	end
		
	def snap_move
		@@selector.snap
	end
		
	def draw(active=true)
		#time = Gosu::milliseconds % 16.66
		if @fade == :in
			@op = [@op + @fade_speed, 255].min
			@scale += @grow_speed if @scale < 1.0
		elsif @fade == :out
			@op = [@op - @fade_speed, 0].max
			@scale -= @grow_speed if @scale > 0.50
		end
		@fade = nil if @op == @stop
		if active
			color = Gosu::Color.new(@op,255,255,255)
		else
			color = Gosu::Color.new(@op,127,127,127)
		end
		@bg.draw(@x,@y,ZIndex::UI,@scale,@scale,color)
		fontcolor = Gosu::Color::YELLOW
		fontcolor.alpha = color.alpha
		@@title_font.draw(@title,@x+32,@y-2,ZIndex::UI,@scale+0.20,@scale+0.20,fontcolor)
		#@title.draw(@x+35,@y,ZIndex::UI,@scale,@scale,color)
		f = @options[0].height
		q = f*(@selected_index+1)
		z = 1
		x = 17
		y = 0
		@options.each { |o| 
			y += (o.height)
			o.draw(@x+x,@y+y+7,ZIndex::UI,@scale,@scale,color)
			z+=1
		}
		@@selector.draw(@scale, color) if active
	end

	def item
		return @opt_names[@selected_index]
	end
	
	def is_done?
		return @op == 0
	end

	def ready?
		return @@selector.ready?
	end
end

class MainMenu < Menu
	def initialize(win, x, y)
		super(win,"Main Menu")
		@win, @x, @y = win, x, y
		self.set_options("Elf")
	end
	
	def to_s
		:Main
	end
end

class ElfMenu < Menu
	def initialize(win, x, y)
		super(win,"Elf Menu")
		@win,@x,@y = win,x,y
		sheet = Gosu::Image.new(win,"sprites/mmziconset.png",true)
		@red = Gosu::Image.new(win,sheet,true,50,0,40,40)
		@green = Gosu::Image.new(win,sheet,true,95,0,40,40)
		@blue = Gosu::Image.new(win,sheet,true,140,0,40,40)
		@opt_names = [:Back, :Red, :Green, :Blue]
		@options = [Gosu::Image::from_text(win,"Back", Gosu::default_font_name,25,1, @bg.width-10,:left),
						@red,@green,@blue]
	end
	
	def to_s
		:Elf
	end
	
	def inspect
		self.to_s
	end
end

class MenuHandler
	def initialize(win,start_x,start_y)
		@win = win
		@active_ui = nil
		@origin_x,@origin_y = start_x,start_y
		@inactive_ui = []
		@menus = {}
		self.addmenu(:Main, ElfMenu.new(win,start_x,start_y))
	end
	
	def addmenu(name,menu)
		@menus[name]=menu
	end
	
	def push_ui(u)
		@inactive_ui.push @active_ui
		@active_ui = u
	end
	
	def pop_ui()
		@inactive_ui.pop
	end
	
	def update
		if @active_ui and @active_ui.is_done?
			if @inactive_ui.length > 0
				@active_ui = @inactive_ui.pop
			else
				@active_ui = nil
			end
		end
	end
	
	def draw
		return unless @active_ui  #just in case
		if @inactive_ui.length > 0
			@inactive_ui.each { |u|
				u.draw false
			}
		end
		@active_ui.draw
	end
	
	def active?
		return (@active_ui != nil)
	end
	
	def prev
		return unless @active_ui
		@active_ui.prev
	end
	
	def next
		return unless @active_ui
		@active_ui.next	
	end
	
	def open
		return if @active_ui
		idx = :Main
		idx = @menus.keys[0] unless @menus.keys.index(:Main)
		@active_ui = @menus[idx]
		#puts "activated #{@active_ui}"
		@active_ui.fadein
	end
	
	def confirm
		#puts "menu action: #{@menus[@active_ui.item.to_sym]}"
		return unless @active_ui and @active_ui.ready?
		if @menus[@active_ui.item.to_sym] and @active_ui.item != :Back
			@inactive_ui.push @active_ui
			@active_ui = @menus[@active_ui.item.to_sym]
			@active_ui.fadein
		elsif @active_ui.item == :Back
			@active_ui.clear
			@active_ui.item.to_sym
		else
			#puts @active_ui.item
			@active_ui.item.to_sym
		end
	end
	
	def cancel
		@active_ui.clear if @active_ui
	end

	def to_s
		"#{@active_ui}"
	end
end

# class GameWindow < Gosu::Window
	# def initialize
		# super(640,480,false)
		# @mh = MenuHandler.new self, 50,50
	# end
		
	# def update
		# @mh.update
	# end
	
	# def draw
		# @mh.draw
	# end
	
	# def button_down(id)
		# case id
			# when Gosu::KbSpace
				# if @mh.active?
					# @mh.cancel
				# else
					# @mh.open
				# end
			# when Gosu::KbDown
				# @mh.next if @mh.active?
			# when Gosu::KbUp
				# @mh.prev if @mh.active?
			# when Gosu::KbEnter, Gosu::KbReturn
				# @mh.confirm if @mh.active?
			# when Gosu::KbEscape
				# close
		# end
	# end
# end

# GameWindow.new.show