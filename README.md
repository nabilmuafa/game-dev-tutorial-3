# Tutorial 3 Game Development

Muhammad Nabil Mu'afa - 2206024972

## Implementasi Fitur Lanjutan

Pada tutorial kali ini, saya memilih untuk mengimplementasikan **dua** fitur lanjutan terkait pergerakan player.

### Double Jump

Untuk mengimplementasikan double jump, saya membuat sebuah variabel yang menghitung jumlah lompat player saat ini, bernama `jump_count`. Kemudian, bagian script yang memeriksa apakah player `is_in_floor()` sebelum lompat bisa dihapus dan diganti dengan memeriksa apakah `jump_count < 2`. Idenya, ketika player lompat sekali, maka `jump_count` akan di-increment. Player bisa melakukan jump sekali lagi dan `jump_count` akan kembali di-increment sehingga bernilai `2`. Jika `jump_count` sudah sama dengan `2`, player tidak bisa lompat lagi dan `jump_count` perlu di-reset jika player sudah kembali `is_in_floor()`. Di sini, perlu ada modifikasi pada baris kode yang menghitung _vertical velocity_ yang mempertimbangkan apakah player saat ini sedang `is_on_floor()`.

Sebelumnya:

```py
func _physics_process(delta):
    velocity.y += delta * gravity

    if is_on_floor() and Input.is_action_just_pressed('ui_up'):
        velocity.y = jump_speed

```

menjadi:

```py
func _physics_process(delta):
    if not is_on_floor():
        velocity.y += delta * gravity
    else:
        jump_count = 0

    if jump_count < 2 and Input.is_action_just_pressed('ui_up'):
		velocity.y = jump_speed
		jump_count += 1
```

### Dash

Untuk mengimplementasikan dash, saya melakukan cukup banyak modifikasi. Sebelumnya, ketika tombol panah ditekan, yang akan di-update secara langsung adalah nilai `velocity.x` sesuai dengan arah jalan. Setelah modifikasi, variabel yang saya update secara langsung adalah `direction`, lalu baru ada assignment ke `velocity.x` yang mengalikan kecepatan player dengan direction (-1 ke kiri, 1 ke kanan).

```py
func _physics_process(delta):
	var direction = Vector2.ZERO

    # ...

    if Input.is_action_pressed("ui_left"):
            direction.x += -1
        elif Input.is_action_pressed("ui_right"):
            direction.x += 1

    ...

    if direction != Vector2.ZERO:
                velocity.x = walk_speed * direction.x
            else:
                velocity.x = 0
```

Selanjutnya, pada game platformer, biasanya dash hanya berlaku jika tap arah dilakukan dua kali dalam durasi singkat yang sudah ditentukan. Ini bisa diimplementasikan dengan timer yang mengukur waktu antara dua kali tap tombol arah. Akan tetapi, hal ini tidak bisa diukur dengan memasang timer pada if statement dengan `Input.is_action_pressed()`, karena fungsi tersebut triggered selama tombol ditekan sehingga timer justru akan menghitung "kapan terakhir tombol ditekan" dengan melihat kapan tombol tersebut di-release.

Sebagai gantinya, saya menggunakan `Input.is_action_just_pressed()` yang hanya akan triggered **saat** tombol ditekan, bukan **selama**. Selain itu, saya juga menyimpan arah terakhir yang ditekan player untuk menentukan apakah tombol yang selanjutnya ditekan nantinya memiliki arah yang sama.

```py
# di luar _physics_process(delta)
var last_tap_time = 0
var last_direction = 0

#...

    if Input.is_action_just_pressed("ui_left"):
        last_tap_time = Time.get_ticks_msec() / 1000
        last_direction = -1

    elif Input.is_action_just_pressed("ui_right"):
        last_tap_time = Time.get_ticks_msec() / 1000
        last_direction = 1
```

Selanjutnya, saya buat variabel baru yang menyimpan interval waktu yang dianggap sebagai dash yang valid, bernama `run_tap_interval`. Kemudian, di dalam `Input.is_action_just_pressed()` yang sudah diimplementasikan, saya menambahkan if statement yang sama secara nested (akan true jika arah yang sama ditekan secara cepat dua kali), ditambah dengan memeriksa apakah waktu antar tap lebih kecil dari `run_tap_interval` dan apakah `last_direction` sama dengan arah tap saat ini.

```py
# di luar _physics_process(delta)
var run_tap_interval = 0.10

# ...
	if Input.is_action_just_pressed("ui_left"):
		if Input.is_action_just_pressed("ui_left") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			print("Left dash")
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = -1

	elif Input.is_action_just_pressed("ui_right"):
		if Input.is_action_just_pressed("ui_right") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			print("Right dash")
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = 1
```

Selanjutnya, saya membuat boolean baru bernama `is_dashing` yang berupa state apakah saat ini player sedang dash. Saya juga membuat variabel `dash_speed` untuk mengatur kecepatan player saat dash, `dash_duration` sebagai batas durasi player bisa dash, dan `dash_timer` sebagai variabel yang bertanggungjawab untuk menghitung berapa lama dash sudah berjalan.

Idenya adalah, ketika dash aktif, `dash_timer` akan di-set ke `dash_duration` dan akan dikurangi oleh `delta` sampai nilainya 0 lagi. Selama durasi ini, player bisa memiliki velocity yaitu `dash_speed`.

Supaya mirip dengan game platformer pada umumnya, saya juga mencoba-coba memakai linear interpolation untuk mengurangi dash speed pemain ke normal speed selama dash berlangsung, supaya ada efek "smooth" dari dash speed ke normal speed.

```py
@export var dash_speed = 1500
@export var dash_duration = 0.5

# ...

var is_dashing = false
var dash_timer = 0.0

# ...
    if Input.is_action_just_pressed("ui_left"):
		if Input.is_action_just_pressed("ui_left") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			start_dash(-1)
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = -1

	elif Input.is_action_just_pressed("ui_right"):
		if Input.is_action_just_pressed("ui_right") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			start_dash(1)
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = 1

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		else:
			velocity.x = lerp(velocity.x, walk_speed * direction.x, 5 * delta)
	else:
		if direction != Vector2.ZERO:
			velocity.x = walk_speed * direction.x
		else:
			velocity.x = 0

    move_and_slide()

func start_dash(dir):
	is_dashing = true
	dash_timer = dash_duration
	velocity.x = dash_speed * dir
```

## Polishing

### Custom Gravity

Menggunakan value-value yang ada di tutorial, saya merasa efek jump yang diimplementasikan kurang "enak", tidak seperti platformer-platformer lain yang pernah saya mainkan. Oleh karena itu, saya mencoba mengimplementasikan gravitasi sendiri. Untuk bagian ini, sebagian besar saya mereferensikan video ini: https://www.youtube.com/watch?v=IOe1aGY6hXA

Secara garis besar, alih-alih menggunakan negative velocity, gravitasi di implementasi saya akan memanfaatkan `jump_height` yaitu jarak lompat yang bisa ditempuh player, `jump_time_to_peak` yaitu waktu player untuk sampai di puncak lompat, dan `jump_time_to_descent` yaitu waktu player untuk jatuh kembali ke bawah. Dari ketiga variabel tersebut, barulah dihitung velocity dan gravity untuk masing-masing tahap (`jump_velocity`, `jump_gravity`, `fall_gravity`). Ketika player pertama lompat, `velocity.y` akan di-assign dengan `jump_velocity`, kemudian selama di udara barulah velocity tersebut akan disesuaikan dengan custom gravity yang sudah dibuat.

```
@export var jump_height : float
@export var jump_time_to_peak : float
@export var jump_time_to_descent : float

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1

# ...

func _physics_process(delta):
    # ...
    if not is_on_floor():
		velocity.y += get_custom_gravity() * delta
    # ...

    if jump_count < 2 and Input.is_action_just_pressed('ui_up'):
		velocity.y = jump_velocity
		# ...

func get_custom_gravity() -> float:
	return jump_gravity if velocity.y > 0.0 else fall_gravity
```

### Animated Sprite

Untuk implementasi animated sprite, sebagian besar saya mereferensikan video ini: https://www.youtube.com/watch?v=tfdXgiMwUBw

Singkatnya, animated sprite dapat diimpor menggunakan spritesheet. Di sini, saya pakai spritesheet bebek. Dari spritesheet ini, saya bisa memilih frame mana saja yang mau dijadikan animasi, kemudian animasi ini bisa di-loop dan diberikan nama serta di-play dalam state-state tertentu. Saya membuat 2 animasi, yaitu `idle` dan `walk`. Untuk menyesuaikan tampilan sprite dengan arah geraknya, saya memanfaatkan atribut `flip_h` dari `AnimatedSprite2D`.

```
@onready var anim = $AnimatedSprite2D

# ...

    if Input.is_action_just_pressed("ui_left"):
        anim.flip_h = false
    # ...
    elif Input.is_action_just_pressed("ui_right"):
		anim.flip_h = true

    # ...
    if direction != Vector2.ZERO:
			anim.play("walk")
			velocity.x = walk_speed * direction.x
		else:
			anim.play("idle")
			velocity.x = 0

func _ready() -> void:
	anim.play("idle")
```

## Referensi

[YouTube - Making a Jump You Can Actually Use In Godot](https://www.youtube.com/watch?v=IOe1aGY6hXA)  
[YouTube - Godot 4.3 Double Jump Tutorial || Weekly Godot Challenge #17](https://www.youtube.com/watch?v=DW4CQoYddXQ)  
[YouTube - Godot 4 Animated Sprite Tutorial | 2D & 3D](https://www.youtube.com/watch?v=tfdXgiMwUBw)
