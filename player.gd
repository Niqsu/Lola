extends CharacterBody2D

@onready var coyoteTimer := $coyoteTimer
@onready var jumpTimer := $jumpTimer
@onready var playerSpr := $sprPlayer

@export var gravity:= 1.0
@export var jumpGravity:= 0.0
@export var fallGravity:= 0.0
@export var maxGravity:= 10.0

@export var movSpeed:= 0.0
@export var maxSpeed:= 0.0
@export var friction:= 0.0

@export var jumpMin:= 0.0
@export var jumpForce:= 0.0
@export var jumpJuice:= 0.0
@export var jumpBufferValue:= 0.0

var jumpBufferCount:= 0.0
var canJump := true
var isJumping := false
var jumpSignal := false

var canCoyote := false
var coyoTest : bool

var movInput
var jmpInput
var holdJump
var releaseJump

enum state{
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH
}

var currentState = state.IDLE

func _ready():
	pass

func _physics_process(delta):
	handleMovement(delta)
	handleGravity(delta)
	move_and_slide()

func _process(delta):
	pass
	
func handleGravity(delta):
	if not is_on_floor():
		if canCoyote:
			coyoteTimer.start()
			canCoyote = false
		else:
			velocity.y += gravity * delta
			velocity.y = min(velocity.y, maxGravity)
		
	elif is_on_floor():
		jumpJuice = 3.0
		canJump = true
		canCoyote = true
		
	if sign(velocity.y) > 0:
		isJumping = false
		gravity = fallGravity

func handleMovement(delta):
	#GET INPUTS
	movInput = Input.get_action_strength("movRight") - Input.get_action_strength("movLeft")
	jmpInput = Input.is_action_just_pressed("movJump")
	holdJump = Input.is_action_pressed("movJump")
	releaseJump = Input.is_action_just_released("movJump")
	
	#/////////////////////////MOVE CONTROLS/////////////////////////
	#IF IS MOVING
	if movInput != 0:
		#IF CHANGE DIRECTION WHILE MOVING
		if sign(velocity.x) != 0 and sign(velocity.x) != sign(movInput):
			velocity.x = move_toward(velocity.x, 0, (friction * 0.5) * delta)
			
		#MOVEMENT
		velocity.x += movInput * movSpeed * delta
		velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed) #LIMIT TOP SPEED
		
	#IF IS NOT MOVING
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	#/////////////////////////JUMP CONTROLS/////////////////////////
	if releaseJump:
		gravity = fallGravity
		isJumping = false
		
	#STARTS JUMP BUFFERING
	if jmpInput:
		jumpBufferCount = jumpBufferValue
	else:
		jumpBufferCount = max(0, jumpBufferCount - delta)
	
	#STARTS MINIMUM JUMP
	
	#if jmpInput:
		#jumpBufferCount = jumpBufferValue
		#if is_on_floor() and jumpBufferCount > 0.0:
			#doJump()
		#else:
			#if coyoteTimer.time_left > 0:
				#doJump()
	
	if (canJump == true and jumpBufferCount > 0.0 and is_on_floor()) or (jmpInput and coyoteTimer.time_left > 0):
		print_debug("pulo")
		coyoteTimer.stop()
		canJump = false
		isJumping = true
		gravity = jumpGravity
		velocity.y = 0.0
		velocity.y = -jumpMin

	#HOLD JUMP
	if holdJump and isJumping == true and jumpJuice > 0.0:
		gravity = jumpGravity
		velocity.y -= jumpForce
		jumpJuice -= 0.5
	
	flip()

func flip():
	var dir = sign(velocity.x)
	if dir > 0:
		playerSpr.flip_h = false
	elif dir < 0:
		playerSpr.flip_h = true

func handleAnimation():
	if is_on_floor():
		if velocity.x == 0:
			currentState = state.IDLE
		elif velocity.x != 0:
			currentState = state.RUN
	elif not is_on_floor():
		if velocity.y < 0:
			currentState = state.JUMP
		elif velocity.y > 0:
			currentState = state.FALL

func setState(new_state):
	if currentState != new_state:
		currentState = new_state

func doJump():
	coyoteTimer.stop()
	canJump = false
	isJumping = true
	gravity = jumpGravity
	velocity.y = 0.0
	velocity.y = -jumpMin
