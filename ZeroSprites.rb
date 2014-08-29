class SpriteSheet
	def initialize(win,img,tileable = false)
		@win = win
		@tileable = tileable
		if img.is_a? Gosu::Image
			@img = img
		else
			@img = Gosu::Image.new(win,img,tileable)
		end
	end
	
	def getFrame(x,y,w,h)
		Gosu::Image.new(@win,@img,@tileable,x,y,w,h)
	end
end

def framemap(*coords)
	return [] if coords.length % 4 > 0
	map = []
	i = 0
	until i == coords.length
		map.push([coords[i], coords[i+1],coords[i+2],coords[i+3]])
		i+=4
	end
	return map
end

class Sprite
	attr_reader :width, :height
	def initialize(window, file, h, w, playback_speed)
		@animation = Gosu::Image::load_tiles(window, file, h, w, false)
		@fps = playback_speed * GameConfig::Second
		@current_frame = -1
		@width = @animation[0].width
		@height = @animation[0].height
	end
	
	def next_frame
		return @animation[Gosu::milliseconds / @fps % @animation.size]
	end
	
	def pick_frame(pos, max)
		@current_frame = (pos/max.to_f*@animation.size).to_i % @animation.size
	end
	
	def advance_frame
		@current_frame+=1
		@current_frame%=@animation.size
	end
	
	def reset
		@current_frame = 0
	end
	
	def cur_frame
		return @animation[@current_frame]
	end
	
	def [](i)
		@animation[i]
	end
end

class OneShotAnimation < Sprite
	attr_reader :x, :y
	def initialize(window, file, h, w, playback_speed, x = 0, y = 0)
		super(window, file, h, w, playback_speed)
		@last = 0
		@x = x
		@y = y
	end
	
	def start
		@last = Gosu::milliseconds
	end
	
	def auto_play
		if @current_frame+1 >= @animation.size then return self.cur_frame end
		now = Gosu::milliseconds
		if (now - @last) > @fps
			@current_frame += 1
			@last = now
		end
		self.cur_frame
	end
		
	def reverse_play
		if @current_frame-1 < 0 then return self.cur_frame end
		now = Gosu::milliseconds
		if (now - @last) > @fps
			@current_frame -= 1
			@last = now
		end
		self.cur_frame
	end
	
	def endpoint
		@current_frame = @animation.size() -1
	end
	
	def done_is?
		@current_frame == 0
	end
	
	def is_done?
		@current_frame >= @animation.size-1
	end
	
end

class Breakable
	attr_reader :x, :y, :width, :height
	def initialize(window, start_x, start_y)
		@parent = window
		@img = Sprite.new(window,"media/CptnRuby Gem.png", -1, -1, 1)
		@dummy = Gosu::Image.new(window,"media/earth.png", true)
		@hp = 1
		@x = start_x
		@y = start_y
		@width = @img.width
		@height = @img.height
		@sounds = [SoundEffects::Glass1,SoundEffects::Glass2,SoundEffects::Glass3]
	end
	
	def draw(ox, oy)
		if ARGV.index("-hitbox")
			@dummy.draw_as_quad(@x-ox-@width/2, @y-oy-@height/2, Gosu::Color::WHITE,
								@x-ox+@width/2, @y-oy-@height/2, Gosu::Color::WHITE,
								@x-ox+@width/2, @y-oy+@height/2, Gosu::Color::WHITE,
								@x-ox-@width/2, @y-oy+@height/2, Gosu::Color::WHITE,
								ZIndex::Things)
		end
		@img.cur_frame.draw_rot(@x-ox, @y-oy, ZIndex::Things, 25 * Math.sin(Gosu::milliseconds / 133.7))
	end
	
	def hit
		@hp -= 1
		@sounds.sample.play unless ARGV.index("-nosound")
	end
	
	def is_dead?
		@hp < 1
	end
	
	def real_x
		@x-@width/2
	end
	
	def real_y
		@y-@height/2
	end
	
end

class Player
	attr_reader :x, :y, :state, :move_y
	attr_accessor :hp
	def initialize(window)
		@x = 3*50
		@y = 6*50
		@hp = 16
		#sprites
		@port_in = OneShotAnimation.new(window,"sprites/zero_port_in.png",-21,56, 1.0)
		@port_out = OneShotAnimation.new(window,"sprites/zero_port_out.png",40,59, 1.0)
		@standing = Sprite.new(window,"sprites/zero_stand.png", -1, 39, 1)
		@damaged = Sprite.new(window,"sprites/stand_damaged.png",-4,-1,4.0)
		@walking = Sprite.new(window,"sprites/zero_run.png", -11, 38, 1)
		@jumping = Sprite.new(window,"sprites/zero_jump2.png", 37, 49, 4.0)
		@falling = Sprite.new(window,"sprites/zero_fall.png", -6, 51, 4.0)
		@take_damage = OneShotAnimation.new(window,"sprites/take_damage.png",-4,-1,2.0)
		@dummy = Gosu::Image.new(window,"media/Earth.png", true)
		#attacking
		@attack_speed = 1  #increase to speed up
		@jump_saber = OneShotAnimation.new(window,"sprites/zero_saberjump.png", 62,52,@attack_speed)
		@stand_saber = OneShotAnimation.new(window,"sprites/zero_saber.png", 74,44,@attack_speed)
		@attack_anim = nil
		#state
		@state = MutableState.new  #defaults to Standing
		#drawing
		@facing = :right
		@move_x = 0
		@move_y = 0
		@x_offset = 0
		@y_offset = 0
		@mirror = 1
		@img = @standing.cur_frame
		@color = Gosu::Color::WHITE
		@invuln_time = 200
		@inv_timer = 0
		#movement
		@move_speed = 4
		@gravity_pull = 4
		@jump_strength = 6
		@jump_height = 204 #should be evenly divisible by gravity and by jump strength
		@warp_x = @x
		@warp_y = @y
		#meta
		@map = window.map
	end
	
	def poofin
		return if @state.at_state? PlayerState::Incoming or
			      @state.at_state? PlayerState::Outgoing
		@state.add_state PlayerState::Incoming
		@state.rm_state PlayerState::Dead
		#return if @is_incoming or @is_outgoing
		#@is_incoming = true
		@port_in.reset
		SoundEffects::Teleport.play unless ARGV.index("-nosound")
	end
	
	def poofout
		return if @state.at_state? PlayerState::Incoming or
			      @state.at_state? PlayerState::Outgoing
		@state.add_state PlayerState::Outgoing
		@state.rm_state PlayerState::Attacking
		@state.rm_state PlayerState::Moving
		@state.rm_state PlayerState::Jumping
		#return if @is_incoming or @is_outgoing
		#@is_attacking = false
		#@is_outgoing = true
		@port_in.endpoint
		SoundEffects::Teleport.play  unless ARGV.index("-nosound")
	end
	
	def moveto(x,y)
		@x,@y = x,y
	end
	
	def warp(x,y)
		@warp_x, @warp_y = x,y+8
		@state.add_state PlayerState::Warping
		poofout
	end
	
	def would_fit?(offs_x, offs_y)
	# Put this back!
		not @map.solid?(offs_x, offs_y) and #top-left
		not @map.solid?(offs_x+@walking.width, offs_y) and #top-right
		not @map.solid?(offs_x, offs_y+@standing.height) and #bottom-left
		not @map.solid?(offs_x+@walking.width, offs_y+@standing.height) #bottom-right		
		#not @map.solid?(offs_x,offs_y,@img.width,@img.height)
	end
	
	def die
		#death animation here
		@state.rm_state PlayerState::HitStun
		@state.rm_state PlayerState::Invincible
		self.image_update
		@state.add_state PlayerState::Dead
		#self.poofout
	end
	
	def move(move_x)
		#return if @is_incoming or @is_outgoing
		return if @state.at_state? PlayerState::Incoming or
			      @state.at_state? PlayerState::Outgoing
		if move_x != 0
			#@is_moving = true
			@state.add_state PlayerState::Moving
			@move_x = move_x
			if (move_x > 0 and @facing == :left) or (move_x < 0 and @facing == :right)
				@x_offset ^= @walking.width
			end
			if move_x > 0 then 
				@facing = :right 
			elsif move_x < 0 then 
				@facing = :left
			end
		else
			@state.rm_state PlayerState::Moving
			#@is_moving = false
		end
		self.image_update
	end
	
	def attack
		#going to leave this one
		return if @state >= PlayerState::Attacking
		#return if @is_attacking or @is_incoming or @is_outgoing
		#if @is_jumping or @is_falling
		if @state.at_state?(PlayerState::Jumping) or @state.at_state?(PlayerState::Falling)
			@attack_anim = @jump_saber
		else
			@attack_anim = @stand_saber
		end
		@attack_anim.reset
		@attack_anim.start
		#@is_attacking = true
		@state.add_state PlayerState::Attacking
		SoundEffects::Slash.play(0.8) unless ARGV.index("-nosound")
	end
	
	def jump(can_double = false)
		return if (@state.at_state? PlayerState::Falling or @state.at_state? PlayerState::Jumping and
		           !can_double) or
				  @state.at_state? PlayerState::Attacking or 
				  @state.at_state? PlayerState::DoubleJump
		@state.add_state PlayerState::DoubleJump if (@state.at_state? PlayerState::Falling or @state.at_state? PlayerState::Jumping) and
		   can_double and would_fit?(@x, @y - 1) and @state.not_at? PlayerState::DoubleJump
		@state.add_state PlayerState::Jumping
		@jumping.reset
		@move_y = @jump_height
	end

	def update
		self.move_update
		#self.attack_update if @is_attacking
		self.attack_update if @state.at_state? PlayerState::Attacking
		self.image_update
	end
	
	def move_update
		#vertical movement with "gravity"
		#if @is_jumping and @move_y > 0	
		if @state.at_state?(PlayerState::Jumping) and @move_y > 0
			@move_y -= @gravity_pull  #gravitational pull
			if @move_y > 0
				if would_fit?(@x,@y-@jump_strength)
					@jumping.pick_frame @move_y, @jump_height
					@y -= @jump_strength
					@move_y -= @jump_strength
				else #no more up.
					@move_y = 0
					@state.rm_state PlayerState::Jumping
					@state.add_state PlayerState::Falling
					#@is_jumping = false
				end
			else
				@move_y = 0
				@state.rm_state PlayerState::Jumping
				@state.add_state PlayerState::Falling
				#@is_jumping = false
			end
		else #more gravity
			#@is_jumping = false
			@state.rm_state PlayerState::Jumping
			return if @state.at_state? PlayerState::Incoming or @state.at_state? PlayerState::Outgoing or @state.at_state? PlayerState::Dead
			if would_fit?(@x,@y+@gravity_pull)
				@falling.reset unless @state.at_state? PlayerState::Falling
				#@is_falling = true
				@state.add_state PlayerState::Falling
				#@falling.advance_frame
				@y += @gravity_pull
			else
				#@is_falling = false
				@state.rm_state PlayerState::DoubleJump
				if @state.at_state? PlayerState::Falling and @state.at_state? PlayerState::Attacking
					@state.rm_state PlayerState::Attacking
				end
				@state.rm_state PlayerState::Falling
			end
			
		end
		#horiz
		if (@move_x > 0 and !would_fit?(@x+@move_speed, @y)) or
		   (@move_x < 0 and !would_fit?(@x-@move_speed, @y))
			@move_x = 0
		end
		if @move_x > 0
			@move_x -= @move_speed
			@x += @move_speed
		elsif @move_x < 0
			@move_x += @move_speed
			@x -= @move_speed 
		else
			#@is_moving = false 
			@state.rm_state PlayerState::Moving
		end
		#warping
		if @state.at_state? PlayerState::Warping and !@state.at_state? PlayerState::Outgoing
			@x, @y = @warp_x, @warp_y
			@state.rm_state PlayerState::Warping
			poofin
		end
	end
		
	def attack_update
		hitbox_w = (@img.width - @standing.width)  #saber-space
		hitbox_h = @img.height - (@img.height - @standing.height) #overhead saber?
		hitbox_y = @y #+ (@img.height - hitbox_h)
		hitbox_x = @x + (@img.width - hitbox_w) # - (@img.width-hitbox_w) 
		hitbox_x -= @img.width if @facing == :left

		# hitbox_w = @attack_anim.width-@standing.width
		# hitbox_h = @attack_anim.height
		# hitbox_y = @y+@standing.height-hitbox_h
		# hitbox_x = @x+@attack_anim.width-hitbox_w
		# if @facing == :left
			# hitbox_x -= @attack_anim.width
		# end
		
		@map.gems.each { |g|
			touch_x = [[hitbox_x+hitbox_w,g.real_x+g.width].min - [hitbox_x,g.real_x].max, 0].max
			touch_y = [[hitbox_y+hitbox_h,g.real_y+g.height].min - [hitbox_y,g.real_y].max, 0].max
			if touch_x > 0 and touch_y > 0
				g.hit
			end
		}
		@map.baddies.each { |g|
			touch_x = [[hitbox_x+hitbox_w,g.real_x+g.width].min - [hitbox_x,g.real_x].max, 0].max
			touch_y = [[hitbox_y+hitbox_h,g.real_y+g.height].min - [hitbox_y,g.real_y].max, 0].max
			if touch_x > 0 and touch_y > 0
				g.hit
			end
		}
		
	end
	
	def image_update
		if @facing == :right
			@mirror = 1
		else
			@mirror = -1
		end
		@y_offset = 0
		if @inv_timer > 0
			@inv_timer -= 1
		else
			@state.rm_state PlayerState::Invincible
		end
		if @state.at_state? PlayerState::Invincible and @state.not_at? PlayerState::HitStun
			@color = [Gosu::Color::RED, Gosu::Color::BLUE, Gosu::Color::AQUA, Gosu::Color::CYAN, Gosu::Color::YELLOW, Gosu::Color::FUCHSIA].sample
		else
			@color = Gosu::Color::WHITE
		end
		case @state.highest_state PlayerState::Highest
			when PlayerState::Outgoing #@is_outgoing
				@y_offset = -14
				@img = @port_in.reverse_play 
				#because is special
				if @port_in.done_is?		
					@state.rm_state PlayerState::Outgoing
					#@is_outgoing = false
				end
			when PlayerState::Incoming #@is_incoming
				@y_offset = -14
				@img = @port_in.auto_play
				@state.rm_state PlayerState::Incoming  if @port_in.is_done?
			when PlayerState::HitStun
				@img = @take_damage.reverse_play
				@state.rm_state PlayerState::HitStun if @take_damage.done_is?
			when PlayerState::Attacking #@is_attacking
				@img = @attack_anim.auto_play
				@state.rm_state PlayerState::Attacking if @attack_anim.is_done?
			when PlayerState::Falling #@is_falling 
				@img = @falling.next_frame
			when PlayerState::Jumping #@is_jumping 
				@img = @jumping.next_frame
			when PlayerState::Moving #@is_moving 
				@img = @walking.next_frame
			else
				if @hp < 8
					@img = @damaged.next_frame
				else
					@img = @standing.cur_frame #there's only one
				end
		end
	end
	
	def draw
		return if @state.at_state? PlayerState::Dead

		if ARGV.index("-hitbox")
			if @state.at_state? PlayerState::Attacking
				hitbox_w = (@img.width - @standing.width)  #saber-space
				hitbox_h = @img.height - (@img.height - @standing.height) #overhead saber?
				hitbox_y = @y #+ (@img.height - hitbox_h)
				hitbox_x = @x + (@img.width - hitbox_w) # - (@img.width-hitbox_w) 
				hitbox_x -= @img.width if @facing == :left
			else
				hitbox_w = @img.width - (@img.width - @standing.width)  #saber-space
				hitbox_h = @img.height - (@img.height - @standing.height) #overhead saber?
				hitbox_y = @y + (@img.height - @standing.height) #+@img.height-hitbox_h
				hitbox_x = @x # - (@img.width-hitbox_w) 
			end
			@dummy.draw_as_quad(hitbox_x,hitbox_y,Gosu::Color::WHITE,
								hitbox_x+hitbox_w,hitbox_y,Gosu::Color::WHITE,
								hitbox_x+hitbox_w,hitbox_y+hitbox_h,Gosu::Color::WHITE,
								hitbox_x,hitbox_y+hitbox_h,Gosu::Color::WHITE,ZIndex::Player)
		end

		@img.draw(@x +@x_offset, @y+@y_offset, ZIndex::Player, @mirror, 1.0, @color)		

	end
	
	def collision?(o)
		hitbox_w = @img.width - (@img.width - @standing.width)  #saber-space
		hitbox_h = @img.height - (@img.height - @standing.height) #overhead saber?
		hitbox_y = @y + (@img.height - @standing.height) #+@img.height-hitbox_h
		hitbox_x = @x # - (@img.width-hitbox_w) 
		#hitbox_x -= @img.width  if @facing == :left and @state.at_state? PlayerState::Attacking
		touch_x = [[hitbox_x+hitbox_w,o.x+o.width].min - [hitbox_x,o.x].max, 0].max
		touch_y = [[hitbox_y+hitbox_h,o.y+o.height].min - [hitbox_y,o.y].max, 0].max
		if touch_x > 0 and touch_y > 0
			return true
		end
		return false
	end
	
	def respawned?
		if @state.not_at? PlayerState::Outgoing
			@hp = 16
			@state.rm_state PlayerState::Invincible
			return true
		end
		return false
	end
	
	def take_damage(val)
		return if @state.at_state? PlayerState::Invincible

		@hp -= val
		@tmp = Gosu::milliseconds
		@state.add_state PlayerState::Invincible
		@state.add_state PlayerState::HitStun
		@state.rm_state PlayerState::Attacking
		@inv_timer = @invuln_time
		@take_damage.start
		@take_damage.endpoint
		SoundEffects::ZeroHit.play   unless ARGV.index("-nosound")
	end	

	def state_string
		# if @is_incoming then "incoming"
		# elsif @is_outgoing then "outgoing"
		# elsif @is_attacking then "attacking"
		# elsif @is_falling then "falling" 
		# elsif @is_jumping then "jumping" 
		# elsif @is_moving then "walking" 
		# else "standing" end
		case @state.highest_state PlayerState::Highest
			when PlayerState::Warping
			"Warping"
			when PlayerState::Incoming 
			"Incoming"
			when PlayerState::Outgoing 
			"Outgoing"
			when PlayerState::HitStun
			"Hit Stun"
			when PlayerState::Attacking 
			"Attacking"
			when PlayerState::DoubleJump
			"Double Jumping"
			when PlayerState::Jumping 
			"Jumping"
			when PlayerState::Falling 
			"Falling"
			when PlayerState::Moving 
			"Walking"
			else 
			"Standing"
		end
	end
end

class CyberElf
	attr_accessor :color
	def initialize(win)
		@@sheet = SpriteSheet.new(win,"sprites/z123cyberelves.gif",false)
		@color = :Red
		@red = []
		@red.push(@@sheet.getFrame(3,1,16,16))
		@red.push(@@sheet.getFrame(22,1,16,16))
		@red.push(@@sheet.getFrame(40,1,16,16))
		@red.push(@@sheet.getFrame(55,1,16,16))
		@red_sparkle = []
		@red_sparkle.push(@@sheet.getFrame(74,6,7,7))
		@red_sparkle.push(@@sheet.getFrame(80,6,7,7))
		@red_sparkle.push(@@sheet.getFrame(87,6,7,7))
		@red_sparkle.push(@@sheet.getFrame(95,6,7,7))
		@red_sparkles = []
		
		@green = []
		@green.push(@@sheet.getFrame(3,20,16,16))
		@green.push(@@sheet.getFrame(22,20,16,16))
		@green.push(@@sheet.getFrame(40,20,16,16))
		@green_sparkle = []
		@green_sparkle.push(@@sheet.getFrame(74,24,7,7))
		@green_sparkle.push(@@sheet.getFrame(80,24,7,7))
		@green_sparkle.push(@@sheet.getFrame(87,24,7,7))
		@green_sparkle.push(@@sheet.getFrame(95,24,7,7))
		@green_sparkles = []
		
		@blue = []
		@blue.push(@@sheet.getFrame(3,38,16,16))
		@blue.push(@@sheet.getFrame(22,38,16,16))
		@blue.push(@@sheet.getFrame(40,38,16,16))
		@blue.push(@@sheet.getFrame(55,38,16,16))
		@blue_sparkle = []
		@blue_sparkle.push(@@sheet.getFrame(74,42,7,7))
		@blue_sparkle.push(@@sheet.getFrame(80,42,7,7))
		@blue_sparkle.push(@@sheet.getFrame(87,42,7,7))
		@blue_sparkle.push(@@sheet.getFrame(95,42,7,7))
		@blue_sparkles = []
		
	end
	
	def draw(x,y)
		x += Math::cos(Gosu::milliseconds/325)*1.25
		y += Math::sin(2*Gosu::milliseconds/325)*1.25
		case @color
			when :Red
				unless @red_sparkles.length == 0
					@red_sparkles.reject! { |s|
						if s[:oy] >= 7
							true
						else
							s[:oy] += 1/5.0
							s[:s] += 1 if Gosu::milliseconds/160 % @red_sparkle.length == 0
							s[:s] %= @red_sparkle.length
							false
						end
						
					}
				end
				if @red_sparkles.length < 4 and rand(100) < 15
					@red_sparkles.push({:x=>x+rand(@red[0].width),:y=>y+@red[0].height,:oy=>0,:s=>rand(@red_sparkle.length)})
				end
				@red[Gosu::milliseconds/160 % @red.size].draw(x,y,ZIndex::Mobiles)
				@red_sparkles.each { |s|
					@red_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				}
			when :Blue
				unless @blue_sparkles.length == 0
					@blue_sparkles.reject! { |s|
						if s[:oy] >= 7
							true
						else
							s[:oy] += 1/5.0
							s[:s] += 1 if Gosu::milliseconds/160 % @blue_sparkle.length == 0
							s[:s] %= @blue_sparkle.length
							false
						end
					}
				end
				if @blue_sparkles.length < 4 and rand(100) < 15
					@blue_sparkles.push({:x=>x+rand(@blue[0].width),:y=>y+@blue[0].height,:oy=>0,:s=>rand(@blue_sparkle.length)})
				end
				@blue[Gosu::milliseconds/160 % @blue.size].draw(x,y,ZIndex::Mobiles)
				@blue_sparkles.each { |s|
					@blue_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				}
			when :Green
				unless @green_sparkles.length == 0
					@green_sparkles.reject! { |s|
						if s[:oy] >= 7
							true
						else
							s[:oy] += 1/5.0
							s[:s] += 1 if Gosu::milliseconds/160 % @green_sparkle.length == 0
							s[:s] %= @green_sparkle.length
							false
						end
						
					}
				end
				if @green_sparkles.length < 4 and rand(100) < 15
					@green_sparkles.push({:x=>x+rand(@green[0].width),:y=>y+@green[0].height,:oy=>0,:s=>rand(@green_sparkle.length)})
				end
				@green[Gosu::milliseconds/160 % @green.size].draw(x,y,ZIndex::Mobiles)
				@green_sparkles.each { |s|
					@green_sparkle[s[:s]].draw(s[:x],s[:y]+s[:oy],ZIndex::Mobiles)
				}
		end
	end
	
	def [](s)
		case s
			when :red
				@red[Gosu::milliseconds/160 % @red.size]
			when :blue
				@blue[Gosu::milliseconds/160 % @blue.size]
			when :green
				@green[Gosu::milliseconds/160 % @green.size]
		end
	end
end

class EnemyShot
	attr_reader :x, :y, :height, :width, :strength
	def initialize(win,x,y,dir,str = 8)
		@frames = Gosu::Image::load_tiles(win,"sprites/baddie_shot.png",8,-1,false)
		@x,@y=x,y
		@height = @frames[0].height
		@width = @frames[0].width
		@dir=dir
		@strength = str
	end
	
	def draw
		@frames[Gosu::milliseconds/133 % @frames.size].draw(@x,@y,ZIndex::Mobiles)
	end
	
	def is_done?(map)
		x = @x
		y = @y
		case @dir
			when :left
				x -= @frames[0].width
			when :right
				x -= @frames[0].width
			when :up
				y -= @frames[0].height
			when :down
				y += @frames[0].height
		end
		return map.solid?(x, y)
	end
end

class Mettaur < Breakable
	def initialize(win,x,y)
		super(win,x,y)
		@img = Sprite.new(win,"sprites/mettaur.png",22,-1,1)
		@fps = 1
		@x,@y = x,y
	end
		
	def draw(ox, oy)
		off_y = 10
		@img[0].draw(@x-ox, @y+off_y-oy, ZIndex::Things,1.5,1.5)
	end
	
end

class Bomb < Breakable
	def initialize(win,x,y)
		super(win,x,y)
		base = Gosu::Image.new(win,"sprites/rmz1__flopper.png",false)
		@img = [Gosu::Image.new(win,base,false,0,0,20,20),
		        Gosu::Image.new(win,base,false,24,0,20,20),
		        Gosu::Image.new(win,base,false,48,0,20,20),
		        Gosu::Image.new(win,base,false,73,0,20,20)]
		@dummy = Gosu::Image.new(win,"media/earth.png", true)
		@x,@y = x,y
		@height,@width = @img[0].height,@img[0].width
		@fps = 250
		@color = Gosu::Color.new(255,rand(127)+128,rand(127)+128,rand(127)+128)
	end
	
	def draw(ox,oy)
		if ARGV.index("-hitbox")
			@dummy.draw_as_quad(@x-ox, @y-oy, Gosu::Color::WHITE,
								@x-ox+@width, @y-oy, Gosu::Color::WHITE,
								@x-ox+@width, @y-oy+@height, Gosu::Color::WHITE,
								@x-ox, @y-oy+@height, Gosu::Color::WHITE,
								ZIndex::Things)
		end
		@img[Gosu::milliseconds / @fps % @img.size].draw(@x-ox,@y-oy,ZIndex::Things,1.0,1.0,@color)
	end
	
	def update
		#this guy moves
		@x += 4 * Math::sin(Gosu::milliseconds / 333.7)
	end
end

class HealthBar
	def initialize(win)
		sheet = Gosu::Image.new(win,"sprites/mmzhealth.png",false)
		@bg = Gosu::Image.new(win,sheet,false,0,0,30,142)
		@point = Gosu::Image.new(win,sheet,false,8,132,15,3)
	end
	
	def draw(x,y,pts)
		@bg.draw(x,y,ZIndex::UI)
		1.upto(pts) { |p|
			@point.draw(x+7,y + (109 - (6 * p)),ZIndex::UI)
		}
	end
end

class DeathExplosion
	def initialize(win,x = 0,y = 0)
		@img = Gosu::Image::load_tiles(win,"sprites/zero_explode.png",true)
		@x,@y = x,y
		@dist = 0
	end
	
	def update
		@dist += (GameConfig::Width / 320)
	end
	
	def draw
		[*0..8].each { |a|
			@img[Gosu::milliseconds / 133 % @img.size].draw(@x+Gosu::offset_x(a*90,@dist),@y+Gosu::offset_y(a*90,@dist),ZIndex::Player)
		}
	end
	
	def is_done?
		@dist >= GameConfig::Width
	end
end

class ChuuBosu
	attr_reader :x, :y, :width, :height
	def initialize(win,x,y)
		@x,@y = x,y
		@win = win
		sheet = Gosu::Image.new(win,"sprites/mmz2_elecgolem.png",false)
		@body = Gosu::Image.new(win,sheet,false,71,5,64,95)
		@width,@height = @body.width,@body.height
		@insideArms = [Gosu::Image.new(win,sheet,false,2,107,44,69),
					   Gosu::Image.new(win,sheet,false,53,107,44,69)]
		@outsideArms = [Gosu::Image.new(win,sheet,false,103,114,44,69),
				        Gosu::Image.new(win,sheet,false,150,111,44,69)]
		@spark = [Gosu::Image.new(win,sheet,false,75,241,11,11),
				  Gosu::Image.new(win,sheet,false,55,239,16,16),
				  Gosu::Image.new(win,sheet,false,29,233,25,25)]
		@thickShot = [Gosu::Image.new(win,sheet,false,92,246,32,5), #center
					  Gosu::Image.new(win,sheet,false,95,229,31,12), #up-left
					  Gosu::Image.new(win,sheet,false,95,257,31,12)] #down-left
		@thinShot = [Gosu::Image.new(win,sheet,false,134,246,32,5), #center
					 Gosu::Image.new(win,sheet,false,134,229,31,12), #up-left
					 Gosu::Image.new(win,sheet,false,134,256,31,12)] #down-left
		@dropShadow = [Gosu::Image.new(win,sheet,false,36,277,10,3),
					   Gosu::Image.new(win,sheet,false,100,277,10,3),
					   Gosu::Image.new(win,sheet,false,48,277,16,3),
					   Gosu::Image.new(win,sheet,false,112,277,16,3),
					   Gosu::Image.new(win,sheet,false,68,277,24,3),
					   Gosu::Image.new(win,sheet,false,132,277,24,3)]
		@shadow = 0
		@state = 0
		@stateChange = Gosu::milliseconds
		@shotDist = 0
		@shotSpeed = 4
		@onScreen = false
		@hp = 32
		@font = Gosu::Font.new(win,Gosu::default_font_name,20)
		@invuln_time = 125
		@inv_timer = 0
	end

	def duration
		Gosu::milliseconds - @stateChange
	end

	def is_dead?
		@hp < 1
	end
	
	def hit
		unless @inv_timer > 0
			@hp -= 4
			@inv_timer = @invuln_time
		end
	end
	
	def real_x
		@x
	end
	def real_y
		@y
	end
	
	def shoot
		if @state & 2 == 0  #inside
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x-22,@y+9,2)) #top-
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x-22-9,@y+19+23,0))
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x-22,@y+28+23+23,1))  #bottom-
		else
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x+43,@y+20,1)) #top-
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x+43+9,@y+20+23,0))
			@win.add_baddie_shot(ChuubosuShot.new(@win,@x+43,@y+20+23+23,2))  #bottom-
		end	
	end
	
	def update
		case @state
			when 0 #paused
				#do nothing
				if self.duration >= 2000
					@state = 1 + (2*rand(2)) #shift to this position
					@stateChange = Gosu::milliseconds
				end
			when 2
				puts "Panic! Hit state 2!?"
			when 1,3 #ready to charge 
				if self.duration >= 750  #chaaaahhhggg!
					@state = (@state | 4) - (@state & 1)
					@stateChange = Gosu::milliseconds
				end
			when 4,6 #chargin' mah laser
				if self.duration >= 1000 #pew!
					@state += 8
					@stateChange = Gosu::milliseconds
					#@onScreen = true #obsolete
					#this is where we shoot
					self.shoot
					#obsolete
					# if @state == 12
						# @th = :in
					# else
						# @th = :out
					# end
				end
			when 12,14
				if self.duration >= 300 #done
					@state = 0
					@statechange = Gosu::milliseconds
				end
		end
		#obsolete
		# if @onScreen
			# @shotDist += @shotSpeed
			# if @shotDist > 200
				# @onScreen = false   #unnecessary
				# @shotDist = 0
			# end	
		# end
		#dance?
		mod = Math::sin(Gosu::milliseconds / 266) / 6
		@y += mod
		@shadow = [[0,@shadow+mod].max,5].min
		#got hit..
		if @inv_timer > 0
			@inv_timer -= 1
		end
	end
		
	def draw(off_x, off_y)
		x = @x - off_x
		y = @y - off_y
		t = self.duration / 66 % 3
		@body.draw(x,y,ZIndex::Mobiles)
		oa = ia = 0
		ia = 1 if @state & 2 == 0
		oa = 1 - ia
		if @state == 0
			@insideArms[0].draw(x-28,y+7,ZIndex::Mobiles-1)
			@outsideArms[0].draw(x+43,y+13,ZIndex::Mobiles)
		else
			@insideArms[ia].draw(x-28,y+7,1)
			@outsideArms[oa].draw(x+43-(oa*1),y+13-(oa*4),3)
			if @state & 4 == 4 and @state & 2 == 0
				@spark[t].draw_rot(x-22,y+9,rand(360),ZIndex::Mobiles)
				@spark[t].draw_rot(x-22-9,y+19+23,rand(360),ZIndex::Mobiles)
				@spark[t].draw_rot(x-22,y+28+23+23,rand(360),ZIndex::Mobiles)
			elsif @state == 6
				@win.flush
				@spark[t].draw_rot(x+43,y+23,0,ZIndex::Mobiles)
				@spark[t].draw_rot(x+43+9,y+19+24,0,ZIndex::Mobiles)
				@spark[t].draw_rot(x+43,y+15+24+23,0,ZIndex::Mobiles)
			end
		end
		# Shot now detached from object
		# if @onScreen
			# shot = @thinShot[0]
			# shot = @thickShot[0] if Gosu::milliseconds / 100 % 2 == 0
			# if (@th == :in)
				# shot.draw_rot(x-22+Gosu::offset_x(293,@shotDist),y+9+Gosu::offset_y(293,@shotDist),ZIndex::Mobiles,23)
				# shot.draw_rot(x-22-9+Gosu::offset_x(247,@shotDist),y+19+23,ZIndex::Mobiles,0)
				# shot.draw_rot(x-22+Gosu::offset_x(247,@shotDist),y+28+23+23+Gosu::offset_y(247,@shotDist),ZIndex::Mobiles,-23)
			# else #outside arm
				# shot.draw_rot(x+43+Gosu::offset_x(247,@shotDist),y+20+Gosu::offset_y(247,@shotDist),ZIndex::Mobiles,-23)
				# shot.draw_rot(x+43+9+Gosu::offset_x(293,@shotDist),y+20+23,ZIndex::Mobiles,0)
				# shot.draw_rot(x+43+Gosu::offset_x(293,@shotDist),y+20+23+23+Gosu::offset_y(293,@shotDist),ZIndex::Mobiles,23)
			# end
		# end
		@font.draw("HP: #{@hp}", x+25,y+125,ZIndex::UI)
		@dropShadow[@shadow].draw_rot(x+25,y+150-(@shadow.to_i),ZIndex::Mobiles-1,0)
	end
end

class ChuubosuShot
	attr_reader :x, :y, :width, :height
	@@sheet = nil
	@@thickShot = nil
	@@thinShot = nil
	def initialize(win,x,y,type)
		@@sheet = Gosu::Image.new(win,"sprites/mmz2_elecgolem.png",false)  unless @@sheet
		@@thickShot = Gosu::Image.new(win,@@sheet,false,92,246,32,5) unless @@thickShot
		@@thinShot =  Gosu::Image.new(win,@@sheet,false,134,246,32,5) unless @@thinShot
		@shotDist = 0
		@shotSpeed = 4
		@t1 = @t2 = 0
		
		case type
			when 0
				@t1 = 247 #or 293, either would work
				@t2 = 0
			when 1
				@t1 = 247
				@t2 = -23
			when 2
				@t1 = 293
				@t2 = 23
		end
		@x,@y = x,y
		@width,@height = 32,5 #@thickShot[0].width,@thickShot[0].height
	end
	
	def update
		@shotDist += @shotSpeed
		@x += Gosu::offset_x(@t1,@shotSpeed)
		@y += Gosu::offset_y(@t1,@shotSpeed) if @t2 != 0
	end
	
	def draw(ox,oy)
		#for now
		x,y = @x-ox,@y-oy
		shot = @@thinShot
		shot = @@thickShot if Gosu::milliseconds / 100 % 2 == 0
		shot.draw_rot(x,y,ZIndex::Mobiles+2,@t2)
	end
	
	def is_done?(dummy = nil)
		return true if @shotDist > 200
		return false
	end
	
end