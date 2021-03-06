(* Copyright (C) 1992, Digital Equipment Corporation                         *)
(* All rights reserved.                                                      *)
(* See the file COPYRIGHT for a full description.                            *)
(*                                                                           *)
(* Last modified on Tue Mar 24 22:25:39 PST 1992 by muller                   *)
(*      modified on Mon Dec 16 09:46:14 PST 1991 by harrison                 *)

INTERFACE Usyslog;

(*
 * These declarations are taken from <syslog.h>
 *
 * You can't quite do everything from Modula-3 because syslog is like printf.
 *
 * Use the Syslog package instead--it's built on top of this and works better
 * from Modula-3.
 *)

FROM Ctypes IMPORT char_star, int;

(* defines for priorities *)
CONST
  LOG_ALERT = 1;	(* alert -- send to all users *)
  LOG_SALERT = 2;	(* subalert -- send to special users *)
  LOG_EMERG = 3;	(* emergency conditions *)
  LOG_ERROR = 4;	(* error *)
  LOG_ERR = LOG_ERROR; 	(* synonym of LOG_ERROR *)
  LOG_CRIT = 5;	      	(* critical information *)
  LOG_WARNING = 6;	(* warning *)
  LOG_NOTICE = 7;	(* important information *)
  LOG_INFO = 8;	      	(* informational message *)
  LOG_DEBUG = 9;	(* debug level info *)

(*
 *  Mode parameters to initlog.
 *)
CONST
  LOG_NULL = 0;	      	(* don't touch log *)
  LOG_SOUT = 1;	      	(* log standard & diag output *)
  LOG_DIAG = 2;	      	(* log diagnostic output *)
  LOG_INDEP = 3;	(* log independently *)
  LOG_CLOSE = 4;	(* close the log *)

(*
 *  Status parameters to initlog.
 *)
CONST
  LOG_PID = 16_0001;	(* log the pid with each message *)
  LOG_TIME = 16_0002;	(* log the time with each message *)
  LOG_COOLIT = 16_0004;	(* suppress priority stuff *)
  LOG_DGRAM = 16_0010;	(* running over a datagram socket *)

<* EXTERNAL *>
PROCEDURE openlog(
  VALUE ident: char_star;
  VALUE logstat: int);

<* EXTERNAL *>
PROCEDURE syslog(
  VALUE priority: int;
  VALUE message: char_star);

<* EXTERNAL *>
PROCEDURE closelog();

END Usyslog.
