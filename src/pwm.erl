%%% @author Tony Rogvall <tony@rogvall.se>
%%% @copyright (C) 2021, Tony Rogvall
%%% @doc
%%%    Simple api to /sys/class/pwm
%%% @end
%%% Created : 12 Mar 2021 by Tony Rogvall <tony@rogvall.se>

-module(pwm).

-export([chip_list/0]).
-export([number_of_pwms/1]).
-export([export/2, unexport/2]).
-export([set_duty_cycle/3]).
-export([set_period/3]).
-export([set/3]).
-export([enable/2, disable/2]).
-export([polarity/3]).
%% 
-export([chip_dir/1, pwm_dir/2, pwm_item/3]).

-define(PWM_DIR, "/sys/class/pwm").

chip_dir(Ci) ->
    filename:join(?PWM_DIR,"pwmchip"++integer_to_list(Ci)).

pwm_dir(Ci,Pwm) ->
    filename:join(chip_dir(Ci), "pwm"++integer_to_list(Pwm)).

pwm_item(Ci,Pwm,Item) ->
    filename:join(pwm_dir(Ci,Pwm), Item).

chip_list() ->
    case file:list_dir(?PWM_DIR) of
	{error,enoent} ->
	    [];
	{ok,Chips} ->
	    [ list_to_integer(Ci--"pwmchip") || 
		Ci <- Chips, lists:prefix("pwmchip", Ci)]
    end.

number_of_pwms(Ci) ->
    File = filename:join(chip_dir(Ci),"npwm"),
    case file:read_file(File) of
	{error,_} -> 0;
	{ok,Data} ->
	    {N, <<"\n">>} = string:to_integer(Data),
	    N
    end.

export(Ci, Pwm) when
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    File = filename:join(chip_dir(Ci),"export"),
    file:write_file(File, integer_to_list(Pwm)).

unexport(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    File = filename:join(chip_dir(Ci),"unexport"),
    file:write_file(File, integer_to_list(Pwm)).

set_duty_cycle(Ci, Pwm, Duty) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0,
      is_integer(Duty), Duty>=0 ->
    file:write(pwm_item(Ci,Pwm,"duty_cycle"), integer_to_list(Duty)).

set_period(Ci, Pwm, Period) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0,
      is_integer(Period), Period>=0 ->
    file:write(pwm_item(Ci,Pwm,"period"), integer_to_list(Period)).

-define(DEFAULT_PERIOD, 1000000).  %% 1KHz period!

set(Ci, Pwm, Value) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0,
      is_number(Value), Value >= 0, Value =< 100 ->
    PwmDir = pwm_dir(Ci, Pwm),
    file:write(filename:join([PwmDir,"period"]),
	       integer_to_list(?DEFAULT_PERIOD)),
    file:write(filename:join([PwmDir,"duty_cycle"]), 
	       integer_to_list(trunc((Value/100)*?DEFAULT_PERIOD))).

enable(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    file:write(pwm_item(Ci,Pwm,"enable"), "1").

disable(Ci, Pwm) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0 ->
    file:write(pwm_item(Ci,Pwm,"enable"), "0").

polarity(Ci, Pwm, Pol) when 
      is_integer(Ci), Ci>=0,
      is_integer(Pwm), Pwm>=0,
      (Pol =:= normal orelse Pol =:= reversed) ->
    file:write(pwm_item(Ci,Pwm,"polarity"), atom_to_list(Pol)).
