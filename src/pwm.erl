%%% @author Tony Rogvall <tony@rogvall.se>
%%% @copyright (C) 2021, Tony Rogvall
%%% @doc
%%%    Simple api to /sys/class/pwm
%%% @end
%%% Created : 12 Mar 2021 by Tony Rogvall <tony@rogvall.se>

-module(pwm).

-compile(export_all).

-define(PWM_DIR, "/sys/class/pwm").

chip_list() ->
    case file:list_dir(?PWM_DIR) of
	{error,enoent} ->
	    [];
	{ok,Chips} ->
	    [ list_to_integer(Ci--"pwmchip") || 
		Ci <- Chips, lists:prefix("pwmchip", Ci)]
    end.

number_of_pwms(Ci) ->
    File = filename:join([?PWM_DIR,"pwmchip"++integer_to_list(Ci),"npwm"]),
    case file:read_file(File) of
	{error,_} -> 0;
	{ok,Data} ->
	    {N, <<"\n">>} = string:to_integer(Data),
	    N
    end.

export(Ci, Pwm) when
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    File = filename:join([?PWM_DIR,"pwmchip"++integer_to_list(Ci),"export"]),
    file:write_file(File, "1\n").

unexport(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    File = filename:join([?PWM_DIR,"pwmchip"++integer_to_list(Ci),"unexport"]),
    file:write_file(File, "1\n").

pwm_dir(Ci,Pwm) ->
    filename:join([?PWM_DIR,"pwmchip"++integer_to_list(Ci),
		   "pwm"++integer_to_list(Pwm)]).

set(Ci, Pwm, Value) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0,
      is_number(Value), Value >= 0, Value =< 100 ->
    PwmDir = pwm_dir(Ci, Pwm),
    file:write(filename:join([PwmDir,"period"]), "10000000"),
    file:write(filename:join([PwmDir,"duty_cycle"]), 
	       integer_to_list(trunc((Value/100)*10000000))).

set_duty_cycle(Ci, Pwm, Duty) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0,
      is_integer(Duty), Duty>0 ->
    PwmDir = pwm_dir(Ci, Pwm),
    File = filename:join(PwmDir,"duty_cycle"),
    file:write(File, integer_to_list(Duty)).

set_period(Ci, Pwm, Period) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0,
      is_integer(Period), Period>0 ->
    PwmDir = pwm_dir(Ci, Pwm),
    File = filename:join(PwmDir,"period"),
    file:write(File, integer_to_list(Period)).

enable(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0 ->
    PwmDir = pwm_dir(Ci, Pwm),
    File = filename:join(PwmDir,"enable"),
    file:write(File, "1").

disable(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0 ->
    PwmDir = pwm_dir(Ci, Pwm),
    File = filename:join(PwmDir,"enable"),
    file:write(File, "0").

polarity(Ci, Pwm, Pol) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>0,
      (Pol =:= normal orelse Pol =:= reversed) ->
    PwmDir = pwm_dir(Ci, Pwm),
    File = filename:join(PwmDir,"polarity"),
    file:write(File, atom_to_list(Pol)).
