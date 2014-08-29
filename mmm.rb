require 'gosu'
require_relative 'ZeroConfig'
require_relative 'ZeroSprites'
require_relative 'ZeroDialogs'
require_relative 'ZeroMenu'

class Map
	attr_reader :width, :height, :gems, :baddies, :start_x, :start_y
	def initialize(window)
		@window = window
		@tileset = Gosu::Image.load_tiles(window, "sprites/zero_tileset.png", 60, 60, true)
		@bgimg = Gosu::Image.new(window,"media/parallax_space.png",true)
		@gems = []
		@baddies = []
		@baddie_shots = []
		#used because this thing has Events associated with it
		@gems.define_singleton_method(:==) { |rhs|
			self.length == rhs
		}
		@poofs = []
		@tiles = []
		@height = @width = 0
		@level = -1
		if ARGV.index("-debug")
			@mapfiles = [ "media/testmap.txt" ]
		else
			@mapfiles = [ "media/CptnRuby Map1.txt","media/CptnRuby Map2.txt","media/CptnRuby Map3.txt" ]
		end
		self.next_level
	end
	
	def load(filename)
		@gems = []
		@poofs = []
		@explosions = []
		@tiles = []
		@baddies = []
		@baddie_shots = []
		@boss = nil
		lines = File.readlines(filename).map { |line| line.chomp }
		@height = lines.size
		@width = lines[0].size
		@tiles = Array.new(@width) do |x|
			Array.new(@height) do |y|
				case lines[y][x, 1]
					when '1'
						@start_x = x*50
						@start_y = y*50
						nil
					when '"'
						Tiles::Grass
					when '#'
						Tiles::Earth
					when 'd'
						Tiles::FirstQGrass
					when 'p'
						Tiles::SecondQGrass
					when '/'
						Tiles::DiagonalGrass
					when '\\'
						-Tiles::DiagonalGrass
					when 'b'
						-Tiles::FirstQGrass
					when 'q'
						-Tiles::SecondQGrass
					when 'D'
						Tiles::FirstQIce
					when 'P'
						Tiles::SecondQIce
					when 'B'
						-Tiles::FirstQIce
					when 'Q'
						-Tiles::SecondQIce
					when 'i'
						Tiles::Ice
					when 'I'
						Tiles::Cold
					when 'g'
						@gems.push(Breakable.new(@window, x *50+25, y*50+25))
						nil
					when 'm'
						@baddies.push(Mettaur.new(@window, x*50, y*50+8))
						nil
					when 'c'
						@boss = ChuuBosu.new(@window, x*50, y*50+25)
						nil
					when 'x'
						@baddies.push(Bomb.new(@window, x*50+25, y*50+25))
						nil
					else
						nil
				end
			end
		end	
	end
  
	def next_level
		@level += 1 unless @level+1 >= @mapfiles.length
		self.load @mapfiles[@level]
	end
  
	def solid?(x, y)
		y < 0 || @tiles[x/50][y/50]
	end
		
	def update (player,elf_color)
		dmg_scale = 1.0
		dmg_scale = 0.5 if elf_color == :Red
		@gems.reject! { |g| 
			if g.is_dead? then 
				@poofs.push(OneShotAnimation.new(@window, "media/poof.png", -8, 30, 0.8,g.x,g.y))
				true 
			else 
				false 
			end 
		}
		@baddies.reject! { |b|
			if b.is_dead? then
				@explosions.push(OneShotAnimation.new(@window, "sprites/mmz1explosion2.gif", -8, -1, 1.15,b.x-33,b.y-33))
				true 
			else 
				b.update if b.class.method_defined? :update
				if elf_color != :Blue and player.collision? b
					player.take_damage 2*dmg_scale
				end
				false 
			end 
		}				
		@poofs.reject! { |p| if p.is_done? then true else false end	}
		@explosions.reject! { |e| 
			if player.collision? e
				player.take_damage((rand(3)+1)*dmg_scale)
			end
			if e.is_done? then true else false end
		}
		if @baddie_shots.length > 0
			@baddie_shots.reject! { |s|
				s.update if s.class.method_defined? :update
				if player.collision? s
					player.take_damage 2*dmg_scale
				end
				if s.is_done? @map
					true
				else
					false
				end
			}
		end
	end
	
	def objOnScreen?(o,ox,oy)
		(o.x-ox).between?(-25,GameConfig::Width+25) and	(o.y-oy).between?(-25,GameConfig::Height+25)
	end
	
	def draw(off_x, off_y)
		@bgimg.draw(-(off_x/(@width*50).to_f*GameConfig::Width),-(off_y/(@height*50).to_f*GameConfig::Height),ZIndex::Background)
		@gems.each { |g| g.draw(off_x,off_y) if objOnScreen?(g,off_x,off_y) }
		@baddies.each { |b| b.draw(off_x, off_y) if objOnScreen?(b,off_x,off_y) }
		@baddie_shots.each { |s| s.draw(off_x,off_y) if objOnScreen?(s,off_x,off_y) } 
		@poofs.each { |p| p.auto_play.draw_rot(p.x-off_x,p.y-off_y,ZIndex::Things,0,0.5,0.5, 1.66, 1.66) if objOnScreen?(p,off_x,off_y) }
		@explosions.each { |p| p.auto_play.draw(p.x-off_x,p.y-off_y,ZIndex::Things,1.0, 1.0) if objOnScreen?(p,off_x,off_y) }
		@height.times { |y|
		    @width.times { |x|
				if @tiles[x][y] and 
				    (x*50).between?(off_x-50,GameConfig::Width+off_x+5) and
					(y*50).between?(off_y-50,GameConfig::Height+off_y+5)
					if @tiles[x][y] >= 0
						@tileset[@tiles[x][y]].draw(x * 50 - 5 - off_x, y * 50 - 5 - off_y, ZIndex::Background)
					else
						@tileset[-@tiles[x][y]].draw(x * 50 + 45 - off_x, y * 50 - 5 - off_y, ZIndex::Background,-1)
					end
				end
			}
		}
	end
	
	def add_baddie_shot(s)
		@baddie_shots.push s
	end
	
	def spawn_boss
		@baddies.push @boss if @boss
	end
end

class GameWindow < Gosu::Window
	attr_reader :map
	def initialize
		super(GameConfig::Width, GameConfig::Height, false)
		BGM.init(self)
		SoundEffects.init(self)
		@map = Map.new(self)
		@player = Player.new(self)
		@elf = CyberElf.new(self)
		@healthbar = HealthBar.new(self)
		@font = Gosu::Font.new(self, Gosu::default_font_name, 20)
		@paused = false
		@camera_x = @camera_y = 0
		@player.moveto(@map.start_x,@map.start_y+10)
		@player.poofin
		@state = MutableState.new
		@state.add_state GameState::UIPaused
		@active_Dialog = nil
		@bgm = nil
		@Menu = MenuHandler.new(self,53,5)
		@Menu.addmenu(:Elf, ElfMenu.new(self, 53, 5))
		@events = {}
		self.init_events
		@active_events = [@events['Intro']]
	end
	
	def update
		@active_events.reject! { |e| 
			e.update
			if e.is_done? 
				e.fire
				true 
			else 
				false 
			end
		}
		
		#adjust volume
		if @bgm 
			if(@state.at_state? GameState::UIPaused or @state.at_state? GameState::PlayerPaused)
				@bgm.volume = 25
			else
				@bgm.volume = 100
			end
		end
		
		
		if @state.at_state? GameState::Playing or
		   @state.at_state? GameState::UIPaused
			@player.update
			@map.update @player,@elf.color
			unless @state.at_state? GameState::UIPaused
				if button_down? GameConfig::BtnConf[0][GameConfig::Right] or
				   button_down? GameConfig::BtnConf[1][GameConfig::Right]
					@player.move(8)
				elsif button_down? GameConfig::BtnConf[0][GameConfig::Left] or
					  button_down? GameConfig::BtnConf[1][GameConfig::Left]
					@player.move(-8)
				end
			end
		end
				
		if @active_Dialog
			@active_Dialog.update if @active_Dialog.class.method_defined? :update
			if @active_Dialog.is_done?
				@active_Dialog = nil
				@state.rm_state GameState::UIPaused
			end
		end
		
		if @Menu.active?
			@Menu.update
		end
		
		if @state.at_state? GameState::UIPaused and !@Menu.active? and !@active_Dialog
			@state.rm_state GameState::UIPaused
		end

		#finally, update the camera
		@camera_x = [[@player.x - (GameConfig::Width/2), 0].max, @map.width * 50 - GameConfig::Width].min
		@camera_y = [[@player.y - (GameConfig::Height/2), 0].max, @map.height * 50 - GameConfig::Height].min
	end
	
	def draw
		@map.draw @camera_x, @camera_y
		@healthbar.draw(6,25,@player.hp)
			if @Menu.active?
				@Menu.draw
			end
		translate(-@camera_x, -@camera_y) do 
			@player.draw
			# off_x = Math::cos(Gosu::milliseconds/325)*1.5
			# off_y = Math::sin(2*Gosu::milliseconds/325)*1.5
			@elf.draw(@player.x-5,@player.y-5)
			if @active_Dialog
				@active_Dialog.draw
			end
		end
		#@font.draw("Active events: #{@active_events.length}", 5, 5, ZIndex::UI, 1.0, 1.0, 0xffffff00)
		#@font.draw("UI Paused", 5, 5, ZIndex::UI) if @state.at_state? GameState::UIPaused
		#@font.draw("#{@active_Dialog}", GameConfig::Width/2, 5, ZIndex::UI)
		text = "#{@map.gems.length} Gems remaining"
		@font.draw("FPS: #{Gosu::fps} #{text}", GameConfig::Width-(text.length*10), 5, ZIndex::UI, 1.0, 1.0, 0xffffff00)
	end
	
	def button_down(id)
		close if id == Gosu::KbEscape
		if id == Gosu::KbBackspace
			#@player.warp @map.start_x, @map.start_y
			@map.spawn_boss  #guaranteed death
		end
		case GameConfig.get_btn id 
			when GameConfig::Up
				if @state.at_state? GameState::UIPaused and @Menu.active?
					@Menu.prev
				end
			when GameConfig::Down
				if @state.at_state? GameState::UIPaused and @Menu.active?
					@Menu.next
				end
			# when GameConfig::Right
				# @player.move(5)
			# when GameConfig::Left
				# @player.move(-5)
			when GameConfig::Jump
				if @state.at_state? GameState::UIPaused and @active_Dialog
					@active_Dialog.cancel if @active_Dialog.class.method_defined? :cancel
				elsif @state.at_state? GameState::UIPaused and @Menu.active?
					@Menu.cancel
					@state.rm_state GameState::UIPaused
				else
					@player.jump @elf.color == :Green
				end
			when GameConfig::Shoot
				if @state.at_state? GameState::UIPaused and @active_Dialog
					@active_Dialog.ok if @active_Dialog.class.method_defined? :ok
				elsif @state.at_state? GameState::UIPaused and @Menu.active?
					#This is specific to Elf menu. which is the Only Menu.
					value = @Menu.confirm
					@elf.color = value unless value == :Back
					@Menu.cancel
				else
					@player.attack
				end
			when GameConfig::Pause
				return if @state.at_state? GameState::UIPaused and @active_Dialog
				if @state.at_state? GameState::UIPaused and @Menu.active?
					@Menu.cancel
					@state.rm_state GameState::UIPaused
				#@state.tog_state GameState::PlayerPaused
				else
					@state.add_state GameState::UIPaused
					@Menu.open @elf.color
				end
		end	
	end
	
	def add_baddie_shot(s)
		@map.add_baddie_shot s
	end
	
	def init_events
		faces = Mugshots.new(self)
		@events['Death'] = GameEvent.new
		@events['Death'].addTrigger { @player.hp < 1 }
		@events['Death'].addAction { @state.add_state GameState::UIPaused;
									 @bgm.stop if @bgm;
									 @player.die;
									 SoundEffects::ZeroDie.play  unless ARGV.index("-nosound")
									 @active_Dialog = DeathExplosion.new(self,@player.x,@player.y)
									 @events['fadeout'].reset
									 @active_events.push(@events['fadeout']);
								   }
		@events['fadeout'] = GameEvent.new
		@events['fadeout'].addTrigger { @active_Dialog == nil }
		@events['fadeout'].addAction { @active_Dialog = Dialogs::Fadeout.new(self);
								       @events['restart_level'].reset
									   @active_events.push(@events['restart_level']); }
		@events['restart_level'] = GameEvent.new
		@events['restart_level'].addTrigger { @active_Dialog.ready? == true }
		@events['restart_level'].addAction { @player.moveto @map.start_x,@map.start_y+10;
		                                     @player.poofin; 
											 @player.hp = 16;
											 @bgm.play  unless ARGV.index("-nosound")
											 @events['Death'].reset
											 @active_events.push(@events['Death']) }
		@events['Intro'] = GameEvent.new
		@events['Intro'].addTrigger { @player.state == PlayerState::Standing }	 
		@events['Intro'].addAction { @state.add_state GameState::UIPaused; 
									 @active_Dialog = Dialogs::PopupBox.new(self,53,3,Dialogs::MissionOneStartText,faces[:Zero]); 
									 @active_events.push(@events['Begin_Music1']); 
									 @active_events.push(@events['Death']);
									 @active_events.push(@events['End_of_level_1_text']) }
		@events['Begin_Music1'] = GameEvent.new
		@events['Begin_Music1'].addTrigger { @active_Dialog == nil }
		@events['Begin_Music1'].addAction { @bgm = BGM::Intro; @bgm.play  unless ARGV.index("-nosound") ; }
		# used by other end-of-level events
		# @events['No_Gems'] = EndlessEvent.new
		# @events['No_Gems'].addTrigger(@map.gems,0)
		@events['End_of_level_1_text'] = GameEvent.new
		@events['End_of_level_1_text'].addTrigger { @map.gems.length == 0 }
		@events['End_of_level_1_text'].addTrigger { @player.state == PlayerState::Standing }
		@events['End_of_level_1_text'].addAction {  @state.add_state GameState::UIPaused; 
													@active_Dialog = Dialogs::PopupBox.new(self,53+@camera_x,3+@camera_y,Dialogs::MissionOneCompleteText,faces[:Zero]); 
													@active_events.push(@events['End_of_level_1']); }
		@events['End_of_level_1'] = GameEvent.new
		@events['End_of_level_1'].addTrigger { @active_Dialog == nil }
		@events['End_of_level_1'].addAction { @bgm.stop if @bgm;
											  @player.poofout; 
											  @active_events.push @events['Start_of_level_2'];}
		@events['Start_of_level_2'] = GameEvent.new
		@events['Start_of_level_2'].addTrigger { !@player.state.at_state? PlayerState::Outgoing } 
		@events['Start_of_level_2'].addAction { @map.next_level; 
												@player.moveto(@map.start_x,@map.start_y+8);
												@player.poofin; 
												@active_events.push(@events['Start_of_level_2_text']) }
		@events['Start_of_level_2_text'] = GameEvent.new
		@events['Start_of_level_2_text'].addTrigger { @player.state == PlayerState::Standing }	 
		@events['Start_of_level_2_text'].addAction { @state.add_state GameState::UIPaused; 
													 @active_Dialog = Dialogs::PopupBox.new(self,53+@camera_x,3+@camera_y,Dialogs::MissionTwoStartText,faces[:Zero]); 
													 @active_events.push(@events['Start_level_2_BGM']);
													 @active_events.push(@events['End_of_level_2_text'])}
		@events['Start_level_2_BGM'] = GameEvent.new
		@events['Start_level_2_BGM'].addTrigger { @active_Dialog == nil }
		@events['Start_level_2_BGM'].addAction { @bgm = BGM::Zero; @bgm.play  unless ARGV.index("-nosound")}
		
		@events['End_of_level_2_text'] = GameEvent.new
		@events['End_of_level_2_text'].addTrigger { @map.gems.length == 0 }
		@events['End_of_level_2_text'].addTrigger { @player.state == PlayerState::Standing }
		@events['End_of_level_2_text'].addAction { @state.add_state GameState::UIPaused; 
													@active_Dialog = Dialogs::PopupBox.new(self,53+@camera_x,3+@camera_y,Dialogs::MissionTwoCompleteText,faces[:Zero]); 
													@active_events.push(@events['End_of_level_2'])}
		@events['End_of_level_2'] = GameEvent.new
		@events['End_of_level_2'].addTrigger { @active_Dialog == nil }
		@events['End_of_level_2'].addAction { @bgm.stop if @bgm; @player.poofout; @active_events.push @events['Start_of_level_3'];}
		@events['Start_of_level_3'] = GameEvent.new
		@events['Start_of_level_3'].addTrigger { !@player.state.at_state? PlayerState::Outgoing } 
		@events['Start_of_level_3'].addAction { @map.next_level; 
												@player.moveto(@map.start_x,@map.start_y+8); 
												@player.poofin; 
												@active_events.push(@events['Start_level_3_BGM']);
												@active_events.push(@events['Start_of_level_3_text']) }
		@events['Start_level_3_BGM'] = GameEvent.new
		@events['Start_level_3_BGM'].addTrigger { @active_Dialog == nil }
		@events['Start_level_3_BGM'].addAction { @bgm = BGM::Cyberelf;@bgm.play  unless ARGV.index("-nosound")}
		
		@events['Start_of_level_3_text'] = GameEvent.new
		@events['Start_of_level_3_text'].addTrigger { @player.state == PlayerState::Standing }	 
		@events['Start_of_level_3_text'].addAction { @state.add_state GameState::UIPaused; 
													 @active_Dialog = Dialogs::PopupBox.new(self,53+@camera_x,3+@camera_y,Dialogs::MissionThreeLoopText,faces[:Ciel]); 
													 @active_events.push @events['Spawn_end_boss'];
												   }
		
		@events['Spawn_end_boss'] = GameEvent.new
		@events['Spawn_end_boss'].addTrigger { @map.gems.length == 0 }
		@events['Spawn_end_boss'].addAction { @map.spawn_boss }
		
		
	end
end

GameWindow.new.show