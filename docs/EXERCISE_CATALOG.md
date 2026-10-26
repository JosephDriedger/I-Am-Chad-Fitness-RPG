# Exercise Catalog

Every exercise a player can log, with how it is recorded, what it needs, and how it is tuned. The table below is generated from the code (`lib/domain/activity.dart` and `lib/domain/exercises.dart`), so it cannot drift. To regenerate it:

```
CATALOG_DOC=docs/EXERCISE_CATALOG.md flutter test test/tool/catalog_doc_test.dart
```

There are **86 exercises** in 6 categories, and every one has an animated demonstration with step-by-step cues. 58 need no gear beyond a floor, a wall or a chair.

## Reading the tables

- **Records** is what the log screen asks for.
- **Tuning** is how the exercise turns into effort minutes (see [Reward rules](REWARD_RULES.md)). "s per rep" is how long one rep really takes. A "×" multiplier is above 1 for hard cardio and below 1 for gentle work. Easier versions of an exercise earn exactly the same as harder ones.
- **Honesty limits** are the reps per set or speed above which the friendly honesty check asks the player to look again. They are deliberately generous.
- **Easier version** is shown in the log screen for anyone who needs it.

## Bodyweight (16)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Push-ups** (`push_up`) | sets, reps | No Equipment | 6 s per rep | 80 reps per set | Wall push-ups are a great place to start. |
| **Squats** (`squat`) | sets, reps | No Equipment | 6 s per rep | 120 reps per set | Try sitting down to a chair and standing back up. |
| **Lunges** (`lunge`) | sets, reps | No Equipment | 5 s per rep | 60 reps per set | Hold a chair or a wall for balance, and take a shorter step. |
| **Reverse Lunges** (`reverse_lunge`) | sets, reps | No Equipment | 5 s per rep | 60 reps per set | Hold a chair or a wall for balance, and take a shorter step back. |
| **Skater Hops** (`skater_hop`) | sets, reps | No Equipment | 3 s per rep | 80 reps per set | Step side to side instead of hopping, and tap your back toe down. |
| **Side Lunges** (`side_lunge`) | sets, reps | No Equipment | 5 s per rep | 60 reps per set | Take a smaller step and hold a chair for balance. |
| **Glute Bridges** (`glute_bridge`) | sets, reps | No Equipment | 5 s per rep | 100 reps per set | – |
| **Donkey Kicks** (`donkey_kick`) | sets, reps | No Equipment | 4 s per rep | 60 reps per set | – |
| **Fire Hydrants** (`fire_hydrant`) | sets, reps | No Equipment | 4 s per rep | 60 reps per set | – |
| **Calf Raises** (`calf_raise`) | sets, reps | Wall | 3 s per rep | 150 reps per set | – |
| **Step-Ups** (`step_up`) | sets, reps | Chair or Step | 4 s per rep | 80 reps per set | Use a lower step and hold a rail or wall. |
| **Wall Sit** (`wall_sit`) | sets, time | Wall | standard | – | Slide down only a short way. Any hold counts. |
| **Jump Squats** (`jump_squat`) | sets, reps | No Equipment | 3 s per rep, × 1.3 | 60 reps per set | Do regular squats, or rise onto your toes at the top instead of jumping. |
| **Chair Dips** (`tricep_dip`) | sets, reps | Chair or Step | 6 s per rep | 60 reps per set | Keep your knees bent and feet close to the chair. |
| **Pike Push-Ups** (`pike_push_up`) | sets, reps | No Equipment | 6 s per rep | 50 reps per set | Put your hands on a chair or step so you are less upside down. |
| **Pull-Ups** (`pull_up`) | sets, reps | Pull-Up Bar | 6 s per rep | 40 reps per set | Use a resistance band for help, or lower down slowly from a step. |

## Core (12)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Sit-Ups / Crunches** (`sit_up`) | sets, reps | No Equipment | 6 s per rep | 120 reps per set | – |
| **Plank** (`plank`) | sets, time | No Equipment | standard | – | A wall plank is a gentle starting point. |
| **Side Plank** (`side_plank`) | sets, time | No Equipment | standard | – | Bend your knees and keep them on the floor. |
| **Bicycle Crunches** (`bicycle_crunch`) | sets, reps | No Equipment | 2 s per rep | 200 reps per set | Keep your feet on the floor and just twist your shoulders. |
| **Leg Raises** (`leg_raise`) | sets, reps | No Equipment | 6 s per rep | 80 reps per set | Raise one leg at a time. |
| **Russian Twists** (`russian_twist`) | sets, reps | No Equipment | 2 s per rep | 200 reps per set | Keep your heels on the floor. |
| **Mountain Climbers** (`mountain_climber`) | sets, reps | No Equipment | 1 s per rep, × 1.3 | 300 reps per set | Put your hands on a chair and move slowly. |
| **Dead Bugs** (`dead_bug`) | sets, reps | No Equipment | 5 s per rep | 60 reps per set | – |
| **Bird Dogs** (`bird_dog`) | sets, reps | No Equipment | 6 s per rep | 60 reps per set | Lift just an arm or just a leg. |
| **Flutter Kicks** (`flutter_kick`) | sets, time | No Equipment | × 1.1 | – | Keep your feet higher and make slower kicks. |
| **Hollow Hold** (`hollow_hold`) | sets, time | No Equipment | standard | – | Bend your knees and keep your arms by your sides. |
| **Superman** (`superman`) | sets, reps | No Equipment | 5 s per rep | 60 reps per set | Lift just your arms, or just your legs. |

## Cardio (14)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Walking** (`walking`) | time, distance | No Equipment | standard | 10 km/h | – |
| **Running / Jogging** (`running`) | time, distance | No Equipment | × 1.25 | 25 km/h | Walk/jog intervals count just as much. |
| **Jumping Jacks** (`jumping_jacks`) | sets, reps | No Equipment | 1 s per rep, × 1.2 | 400 reps per set | Step one foot out at a time instead of jumping. |
| **High Knees** (`high_knees`) | sets, reps | No Equipment | 1 s per rep, × 1.2 | 400 reps per set | March on the spot with lower knees. |
| **Butt Kicks** (`butt_kicks`) | sets, reps | No Equipment | 1 s per rep, × 1.1 | 400 reps per set | Walk on the spot, curling one heel up at a time. |
| **Burpees** (`burpee`) | sets, reps | No Equipment | 4 s per rep, × 1.5 | 50 reps per set | Step back and forward instead of jumping, and skip the jump at the top. |
| **Jump Rope** (`jump_rope`) | time | Cardio Gear | × 1.4 | – | Practice the hop and arm circles with no rope. |
| **Cycling** (`cycling`) | time, distance | Cardio Gear | × 1.1 | 55 km/h | – |
| **Rowing** (`rowing`) | time, distance | Cardio Gear | × 1.3 | 24 km/h | – |
| **Stair Climbing** (`stair_climbing`) | time | Chair or Step | × 1.3 | – | Take it slowly, or climb just a few flights. |
| **Hiking** (`hiking`) | time, distance | No Equipment | × 1.1 | 10 km/h | – |
| **Elliptical** (`elliptical`) | time, distance | Gym Machine | × 1.1 | 18 km/h | – |
| **Shadow Boxing** (`shadow_boxing`) | time | No Equipment | × 1.2 | – | Slow the punches down and take rests between rounds. |
| **Swimming** (`swimming`) | time, distance | Cardio Gear | × 1.3 | 6 km/h | – |

## Resistance (21)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Dumbbell Row** (`dumbbell_row`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Dumbbell Shoulder Press** (`dumbbell_press`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Barbell Squat** (`barbell_squat`) | sets, reps, weight | Barbell | 6 s per rep | 30 reps per set | – |
| **Goblet Squat** (`goblet_squat`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Bicep Curls** (`bicep_curl`) | sets, reps, weight | Dumbbells | 6 s per rep | 50 reps per set | – |
| **Dumbbell Front Raises** (`front_raise`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Good Mornings** (`good_morning`) | sets, reps | No Equipment | 5 s per rep | 40 reps per set | Hinge only as far as feels comfortable, with your hands on your hips. |
| **Dumbbell Lunges** (`dumbbell_lunge`) | sets, reps, weight | Dumbbells | 5 s per rep | 40 reps per set | Practise without weights first, or hold a chair for balance. |
| **Lateral Raises** (`lateral_raise`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Overhead Tricep Extension** (`overhead_tricep_extension`) | sets, reps, weight | Dumbbells | 6 s per rep | 40 reps per set | – |
| **Bench Press** (`bench_press`) | sets, reps, weight | Barbell | 6 s per rep | 40 reps per set | – |
| **Deadlift** (`deadlift`) | sets, reps, weight | Barbell | 6 s per rep | 30 reps per set | – |
| **Romanian Deadlift** (`romanian_deadlift`) | sets, reps, weight | Dumbbells | 6 s per rep | 30 reps per set | – |
| **Barbell Overhead Press** (`overhead_press`) | sets, reps, weight | Barbell | 6 s per rep | 30 reps per set | – |
| **Barbell Row** (`barbell_row`) | sets, reps, weight | Barbell | 6 s per rep | 30 reps per set | – |
| **Hip Thrust** (`hip_thrust`) | sets, reps, weight | Chair or Step | 6 s per rep | 50 reps per set | Do it with no weight, or do glute bridges on the floor. |
| **Lat Pulldown** (`lat_pulldown`) | sets, reps, weight | Gym Machine | 6 s per rep | 40 reps per set | – |
| **Leg Press** (`leg_press`) | sets, reps, weight | Gym Machine | 6 s per rep | 60 reps per set | – |
| **Kettlebell Swing** (`kettlebell_swing`) | sets, reps, weight | Kettlebell | 3 s per rep, × 1.2 | 80 reps per set | – |
| **Farmer's Carry** (`farmer_carry`) | time, distance, weight | Dumbbells | × 1.2 | 8 km/h | – |
| **Resistance Band Row** (`band_row`) | sets, reps | Resistance Band | 6 s per rep | 60 reps per set | – |

## Mobility & Recovery (18)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Stretching** (`stretching`) | time | No Equipment | × 0.6 | – | – |
| **Light Mobility** (`light_mobility`) | time | No Equipment | × 0.6 | – | – |
| **Cat-Cow** (`cat_cow`) | time | No Equipment | × 0.6 | – | – |
| **Child's Pose** (`child_pose`) | time | No Equipment | × 0.6 | – | – |
| **Downward Dog** (`downward_dog`) | time | No Equipment | × 0.7 | – | – |
| **Cobra Stretch** (`cobra_stretch`) | time | No Equipment | × 0.6 | – | – |
| **Hamstring Stretch** (`hamstring_stretch`) | time | No Equipment | × 0.6 | – | – |
| **Quad Stretch** (`quad_stretch`) | time | Wall | × 0.6 | – | – |
| **Hip Flexor Stretch** (`hip_flexor_stretch`) | time | No Equipment | × 0.6 | – | – |
| **Shoulder Stretch** (`shoulder_stretch`) | time | No Equipment | × 0.6 | – | – |
| **Side Bend** (`side_bend`) | time | No Equipment | × 0.6 | – | – |
| **Seated Spinal Twist** (`spinal_twist`) | time | Chair or Step | × 0.6 | – | – |
| **Butterfly Stretch** (`butterfly_stretch`) | time | No Equipment | × 0.6 | – | – |
| **Arm Circles** (`arm_circles`) | time | No Equipment | × 0.6 | – | – |
| **Calf Stretch** (`calf_stretch`) | time | Wall | × 0.6 | – | – |
| **Hip Circles** (`hip_circles`) | time | No Equipment | × 0.6 | – | – |
| **Tai Chi** (`tai_chi`) | time | No Equipment | × 0.7 | – | – |
| **Sun Salutation** (`sun_salutation`) | time | No Equipment | × 0.8 | – | – |

## Sports & Play (5)

| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |
| --- | --- | --- | --- | --- | --- |
| **Basketball** (`basketball`) | time | Ball or Court | × 1.2 | – | – |
| **Soccer** (`soccer`) | time | Ball or Court | × 1.2 | – | – |
| **Tennis** (`tennis`) | time | Ball or Court | × 1.1 | – | – |
| **Dancing** (`dancing`) | time | No Equipment | standard | – | – |
| **Martial Arts** (`martial_arts`) | time | No Equipment | × 1.2 | – | – |

## Adding an exercise

1. **Describe it** in `lib/domain/exercises.dart`: a stable snake_case `id` (never rename it, because workouts store it), a Title Case `name`, the `category`, which `metrics` it records, and a short, calm, conservative `formCue`. Add an `easierAlternative` whenever there is a gentler way to do it, and an `equipment` tag.
2. **Tune it.** Set `secondsPerRep` to how long one rep really takes and an `effortFactor` that fits (1.0 is a brisk walk). Distance exercises need `minutesPerKm` and `plausibleKmh`; rep exercises need `plausibleRepsPerSet`. The catalog tests fail if these are missing or out of range.
3. **Animate it.** Write a pose with `_rig` in a file under `lib/game/demo/` (keyframes of torso, hand and foot targets, solved with the same IK as every other demo), then add an entry with its three cues to `demo_catalog.dart`. Draw props in `demo_props.dart`.
4. **Look at it.** Render a contact sheet and check every demo by eye:

   ```
   DEMO_SHEET=<folder> DEMO_IDS=your_id flutter test test/tool/demo_sheet_test.dart
   ```

5. **Run the tests.** The demo tests check that limbs never stretch, nothing sinks through the floor, the loop closes, motion is smooth, and the exercise really moves. Then regenerate this document.

## Safety and review

Cues are written to be conservative: they ask people to go at their own pace, stop if anything hurts, and use spotters or coaching for heavy lifts. The animations and cues have **not** been reviewed by a qualified trainer or physiotherapist yet, and that review is on the [roadmap](ROADMAP.md). This is a game, not medical advice.
