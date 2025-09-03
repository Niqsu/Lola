extends CharacterBody2D

@onready var playerSpr := $sprPlayer
@onready var jumpTimer:= $jumpBuffer
@onready var coyoteTimer:= $coyoteTimer

@export var movSpeed:= 0.0
@export var maxSpeed:= 0.0
@export var friction:= 0.0

@export var jumpHeight : float
@export var jumpTimePeak : float
@export var jumpTimeDescent : float

@onready var jumpVelocity : float = ((2.0 * jumpHeight) / jumpTimePeak) * -1.0
@onready var jumpGravity : float = ((-2.0 * jumpHeight) / (jumpTimePeak * jumpTimePeak)) * -1.0
@onready var fallGravity : float = ((-2.0 * jumpHeight) / (jumpTimeDescent * jumpTimeDescent)) * -1.0

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
	velocity.y += getGravity() * delta
	
	handleMovement(delta)
	
	if Input.is_action_just_pressed("movJump"):
		handleJump()

	if is_on_floor():
		coyoteTimer.start()
		if not jumpTimer.is_stopped():
			jump()
			jumpTimer.stop()
			
	move_and_slide()

func handleJump():
	if is_on_floor() or not coyoteTimer.is_stopped():
		jump()
		jumpTimer.stop()
	else:
		if jumpTimer.is_stopped():
			jumpTimer.start()

func _process(delta):
	pass

func getGravity() -> float:
	return jumpGravity if velocity.y < 0.0 else fallGravity

func jump():
	velocity.y = jumpVelocity

func handleMovement(delta):
	#GET INPUTS ============================
	var movInput = Input.get_action_strength("movRight") - Input.get_action_strength("movLeft")
	var jmpInput = Input.is_action_just_pressed("movJump")
	var holdJump = Input.is_action_pressed("movJump")
	var releaseJump = Input.is_action_just_released("movJump")
	
	#MOVE CONTROLS ============================
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
