//The use of classes was avoided to keep in line with C programming
//image taken from https://commons.wikimedia.org/wiki/File:Pink_or_Plum_Robot_Face_With_Green_Eyes.png and modified

import processing.serial.*;
Serial my_port;
float previous_port_value = 0;

final int canvas_width = 800;
final int half_canvas_height = 350;
final int divider_height = 10;

//=====Game variables=====
final int robot_width = 50;
final int robot_height = 50;
final int robot_xpos = 50;
final int pipe_width = 10;
int[] pipe_xpos = new int[4];
int[] top_pipe_length = new int[4];
int[] bottom_pipe_length = new int[4];
float median_ADC;
boolean is_game_running = true;
PImage robot_img;
int score;

//=====Graph variables=====
float[] line_x_pos = new float[800];
float[] line_y_pos = new float[800];
final int max_ADC_value = 1023;
final int graph_padding = 20; //padding for top and bottom of graph

void setup()
{
  size(800, 710);
  String port_name = Serial.list()[0]; 
  my_port = new Serial(this, port_name, 9600);
  
  init_pipe_pos();
  median_ADC = get_median_ADC();
  robot_img = loadImage("robot.jpg");
  score = 0;
  
  init_line_pos();
}

void draw()
{
  background(0,0,0);
  noStroke();
  
  //=====Game functions=====
  if (is_game_running == true)
  {
    draw_rect();
    draw_pipes();
    shift_pipe_left();
    draw_score();
    if (check_collision() == true)
    {
      is_game_running = false;
    }
    add_pipe();
  } else{
    end_game();
  }
  
  draw_divider(); //divider between the game and the graph
    
  //=====Graph functions=====
  draw_lines();
  shift_graph_left();
  line_y_pos[799] = get_line_y_pos();
}

Float get_port_value() //returns raw ADC from port
{
  String port_value;
  if (my_port.available() > 0) 
    { 
      port_value = my_port.readStringUntil('\n');
    } else{
      port_value = null; 
    }
    
  if (port_value != null)
    {
      previous_port_value = float(port_value);
      return float(port_value);
    } else{
      return previous_port_value;
    }
}

void draw_divider() //draws a line between the game and the graph
{
  fill(255,153,0);
  rect(0, half_canvas_height, canvas_width, divider_height);
}

//=====Game Code=====
float get_median_ADC()  //returns median ADC used to callibrate corresponding Y-axis position of robot
{
  int i;
  float[] median_ADC_arr = new float[31];
  get_port_value();
  delay(1000); //get_port_value and delay() is called here to minimise fluctuations that occur when get_port_value is called for the first time
  for (i = 0; i <= 30; i++)
  {
    median_ADC_arr[i] = get_port_value();
    delay(100);
  }
  median_ADC_arr = sort(median_ADC_arr);
  return median_ADC_arr[16];
}

void init_pipe_pos()
{
  int i = 0;
  int x;
  for (x = 600; x <= 1200; x+=200)
  {  
    pipe_xpos[i] = x;
    set_pipe_lengths(i);
    i++;
  }
}

void set_pipe_lengths(int i)
{
  top_pipe_length[i] = int(random(half_canvas_height));
  bottom_pipe_length[i] = int(random(half_canvas_height));
  
  while((half_canvas_height - top_pipe_length[i] - bottom_pipe_length[i] <= robot_height + 20) ||
  (half_canvas_height - top_pipe_length[i] - bottom_pipe_length[i] >= 250))
  { //regenerates top and bottom pipe length value if the gap betweens pipes is too big or too small
    top_pipe_length[i] = int(random(half_canvas_height));
    bottom_pipe_length[i] = int(random(half_canvas_height));
  }
}

void draw_rect()
{
  image(robot_img, robot_xpos, get_robot_ypos(), robot_width, robot_height);
}

int get_robot_ypos()
{
  float gradient = (half_canvas_height-0)/(300-median_ADC); //300 is assumed as the raw ADC value of a relatively low light intensity
  float c = half_canvas_height - (gradient * 300); //since y=mx+c, c=y-mx
  int robot_ypos = int((gradient * get_port_value()) + c); //y=mx+c
  int robot_in_bounds = check_robot_in_bounds(robot_ypos);
  
  if (robot_in_bounds == -1){ //if robot is too high, stop it from leaving the canvas
     robot_ypos = 0;
   } else if (robot_in_bounds == 1){ //if robot is too low, stop it from leaving the canvas
     robot_ypos = half_canvas_height - robot_height;
   }
  
  return robot_ypos;
}

int check_robot_in_bounds(int robot_ypos) //returns -1 if too high, 0 if in bounds, 1 if too low
{
  int is_in_bounds = 0;
  
  if(robot_ypos < 0){
    is_in_bounds = -1;
  } else if (robot_ypos + robot_height > half_canvas_height){
    is_in_bounds = 1;
  }
  return is_in_bounds;
}

void draw_pipes()
{
  int i;
  fill(3,255,194);
  for (i = 0; i <= 3; i++)
  {  
    rect(pipe_xpos[i], 0, pipe_width, top_pipe_length[i]);
    rect(pipe_xpos[i], (half_canvas_height - bottom_pipe_length[i]), pipe_width, bottom_pipe_length[i]);
  }
}

void shift_pipe_left()
{
  int i;
  for (i = 0; i <= 3; i++)
  {  
    pipe_xpos[i] -= 1;
  }
}

void add_pipe()
{
  int i = is_add_pipe_needed();
  if (i != -1)
  {
    set_pipe_lengths(i);
    pipe_xpos[i] = canvas_width;
  }
}

int is_add_pipe_needed() //checks if the first pipe has left the canvas. if true, returns the index of the pipe. else, returns -1
{
  int i;
  for (i = 0; i <= 3; i++)
  {  
    if (pipe_xpos[i] == -10)
    {
      return i;
    }
  }
  return -1;
}

boolean check_collision()
{
  int i;
  boolean has_collided = false;
  for (i = 0; i <= 3; i++)
  {  
    if((robot_xpos < pipe_xpos[i] + pipe_width && robot_xpos + robot_width > pipe_xpos[i]) && 
    ((get_robot_ypos() < 0 + top_pipe_length[i] && robot_xpos + get_robot_ypos() > 0) || 
    (get_robot_ypos() < (half_canvas_height - bottom_pipe_length[i]) + bottom_pipe_length[i] && 
    robot_xpos + get_robot_ypos() > (half_canvas_height - bottom_pipe_length[i])))) 
     { //checks if robot intersects with pipe
        has_collided = true;
     }
  }
  return has_collided;
}

void draw_score()
{ 
  if (check_add_score() == true)
  {
    score += 1;
  }
  String str_score = "Score: " + str(score);
  int score_xpos = canvas_width - 190;
  int score_ypos = 50;
  
  textSize(35);
  fill(255,255,255);
  text(str_score, score_xpos, score_ypos);
}

boolean check_add_score()
{
  int i;
  boolean add_score = false;
  for (i = 0; i <= 3; i++)
  {
    if (robot_xpos == pipe_xpos[i] + pipe_width) //if robot has passed a pipe
    {
      add_score = true;
    }
  }
  return add_score;
}

void end_game()
{
  textSize(canvas_width/20);
  fill(255,0,0);
  textAlign(CENTER);
  text("Game over\nPress r to restart", canvas_width/2, half_canvas_height/2);
}

void keyPressed()
{
  if (key == 'r')
  {
    restart_game();
  }
}

void restart_game()
{
  is_game_running = true;
  init_pipe_pos();
  score = 0;
}

//=====Graph Code=====
void init_line_pos()
{
  int i;
  for (i = 0; i <= 799; i++)
  {
    line_x_pos[i] = i;
    line_y_pos[i] = half_canvas_height + half_canvas_height + divider_height - graph_padding; //init Y-axis values to bottom of the canvas minus the padding
  }
}

void draw_lines()
{
  int i;
  for (i = 0; i <= 798; i++)
  {  
    strokeWeight(5);
    stroke(255,243,0);
    line(line_x_pos[i], line_y_pos[i], line_x_pos[i+1], line_y_pos[i+1]);
  } 
}

float get_line_y_pos()
{
  float port_value = get_port_value();
  float ADC_percentage = (max_ADC_value - port_value) / max_ADC_value;
  int graph_height = half_canvas_height - graph_padding - graph_padding;
  return (ADC_percentage * graph_height) + half_canvas_height + divider_height + graph_padding;
}

void shift_graph_left()
{
  int i;
  for (i = 0; i <= 798; i++)
  {
    line_y_pos[i]= line_y_pos[i+1];
  }
}
