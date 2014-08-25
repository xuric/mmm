module ZIndex
	Background, Things, Mobiles, Player, UI = *0..4
end

module Tiles
	Grass,Earth,Ice,Cold,DiagonalGrass,FirstQGrass,SecondQGrass,FirstQIce,SecondQIce,DiagonalIce = *0..9
end

module PlayerState
	Standing, Invincible, DoubleJump, Moving, Falling, Jumping, Attacking, HitStun, Dead, Warping, Incoming, Outgoing, = *0..11
	Highest = Outgoing
end

module GameState
	Playing,UIPaused,PlayerPaused,GameOver = *0..3
end

module GameConfig
	Height = 480
	Width = 640
	Second = 60  #Updates per second.
	Paused = false
	
	Up,Down,Left,Right,Pause,Shoot,Jump = *0..6
	
	BtnConf = [[ Gosu::KbUp,Gosu::KbDown,Gosu::KbLeft,Gosu::KbRight,Gosu::KbReturn,Gosu::KbQ, Gosu::KbSpace ],
			[   Gosu::GpUp,  		#Up
				Gosu::GpDown,  		#Down
				Gosu::GpLeft,  		#Left
				Gosu::GpRight, 		#Right
				Gosu::GpButton9, 	#Pause
				Gosu::GpButton4,	#Shoot
				Gosu::GpButton0]]  	#Jump
				
	def self.get_btn id
		BtnConf.each { |c| 
			t = c.index id 
			return t unless t == nil
			}
		return nil
	end
	
end

module SoundEffects
	def self.init(window)
		self.const_set(:Slash, Gosu::Sample.new(window,"zero/Saber - Slash.wav"))
		self.const_set(:Teleport, Gosu::Sample.new(window,"zero/Teleport.wav"))
		self.const_set(:ZeroDie, Gosu::Sample.new(window,"zero/Zero - Die.ogg"))
		self.const_set(:ZeroHit, Gosu::Sample.new(window,"zero/Zero - Hit.ogg"))
		self.const_set(:Glass1, Gosu::Sample.new(window,"media/glass_break1.wav"))
		self.const_set(:Glass2, Gosu::Sample.new(window,"media/glass_break2.wav"))
		self.const_set(:Glass3, Gosu::Sample.new(window,"media/glass_break3.wav"))
	end
end

module BGM
	class GameBGM < Gosu::Song
		def initialize(window,filename)
			super(window,filename)
			@fade = 0
		end
		
		def fadeout(ms)
			zend = Gosu::milliseconds + ms
			pct = 0.8
			while Gosu::milliseconds < zend
				gms = Gosu::milliseconds
				pct *= gms.to_f / (gms + ms).to_f
				self.volume = pct
			end
		end		
		
		def fade(pct)
			cur = 0.8
			while cur > pct
				cur *= 0.8
				self.volume = cur
			end
		end
	end

	def self.init(window)
		self.const_set(:Intro, GameBGM.new(window,"zero/Crash.ogg"))
						Intro.volume = 0.8
		self.const_set(:Zero, GameBGM.new(window,"zero/ZERO.ogg"))
						Zero.volume = 0.8
		self.const_set(:Cyberelf, GameBGM.new(window,"zero/Cyberelf.ogg"))
					    Cyberelf.volume = 0.8
	end
	
end

class MutableState
	def initialize
		@state = 1<<0
		@time_last_change = Gosu::milliseconds
	end

	def tog_state(st)
		@state ^= (1 << st)
		@time_last_change = Gosu::milliseconds
	end

	def add_state(st)
		if !self.at_state? st
			self.tog_state st
		end
	end
	
	def rm_state(st)
		if self.at_state? st
			self.tog_state st
		end
	end
	
	def at_state?(st)
		@state & (1<<st) > 0
	end
	
	def not_at?(st)
		!self.at_state?(st)
	end
	
	def highest_state(whence)
		#hmm..
		x = whence
		until self.at_state? x or x == 0
			x -= 1
		end
		x
	end
	
	def duration
		Gosu::milliseconds - @time_last_change
	end
	
	def ==(x)
		@state == (1<<x)
	end
	def !=(x)
		@state != (1<<x)
	end
	def <(x)
		@state < (1<<x)
	end
	def >(x)
		@state < (1<<x)
	end
	def <=(x)
		@state <= (1<<x)
	end
	def >=(x)
		@state >= (1<<x)
	end
	
	def to_s
		@state.to_s
	end
	
end
