UNSAFE MODULE FliClient1 EXPORTS FliClient;
IMPORT Video;
IMPORT Fli;
IMPORT Rofs;
IMPORT Clib;
IMPORT Fmt;

IMPORT Spy;

VAR
  flitimer: Spy.T;

  fbuffer: ARRAY [0..Fli.FILE_HEADER_SIZE] OF CHAR;
  fhbuffer: ARRAY [0..Fli.FRAME_HEADER_SIZE+8] OF CHAR;
  databuffer: ARRAY [0..(16*8192)] OF CHAR;

PROCEDURE load1(fname:TEXT;x:CARDINAL;y:CARDINAL;repeat:CARDINAL) =
  VAR
    dpy: Video.T;
    rc:Rofs.Errors;
    fd:Rofs.T;
    size, index, height, width, frames, bytesread: CARDINAL;
    lsb: BOOLEAN;
    offset: CARDINAL;
  BEGIN
    Clib.Print("FliClient.load1 loading... " & 
      fname & " at (x,y) " & Fmt.Int(x) & "," & Fmt.Int(y) & " repeating " & 
      Fmt.Int(repeat)& "\n");

    (* open fli file *)

    rc := Rofs.Open_file(fd,fname);
    IF rc = Rofs.Errors.NONE THEN    
      dpy := Video.video_new(0);
      Video.video_clear_screen(dpy);
      Video.video_set_screen_pos(dpy,x,y);

      FOR count := 1 TO repeat DO 

        (* read fli header *)
        index := 0;
        size := Fli.FILE_HEADER_SIZE;
        rc := Rofs.Read_file(fd,index,fbuffer,size,bytesread);
        WITH f = fbuffer DO 

          IF rc = Rofs.Errors.NONE AND bytesread = Fli.FILE_HEADER_SIZE AND Fli.fli_magic(f) THEN

            frames := Fli.fli_frames(f);
            height := Fli.fli_height(f);
            width  := Fli.fli_width(f);

            (* read the rest of fli file *)
            FOR i := 1 TO frames DO
              INC(index,bytesread);

              (* read frame header bytes *)
              rc := Rofs.Read_file(fd,index,fhbuffer,BYTESIZE(fhbuffer),bytesread);

              (* verify that we got the right number of bytes *)
              IF rc = Rofs.Errors.NONE AND bytesread = BYTESIZE(fhbuffer) THEN

                (* find the frame header in the bytes just read in *)
                WITH fh = fhbuffer DO 
                IF Fli.fli_read_frame_header(fh,fh,offset,lsb) THEN

                  (* compute size of this frame *)
                  size := Fli.fli_size(fh,Fli.FRAME_HEADER_SIZE_OFFSET,lsb);

                  (* compensate size with frameheader size *)
                  DEC(size,Fli.FRAME_HEADER_SIZE);

                  (* set index to start of frame data *)
                  INC(index,Fli.FRAME_HEADER_SIZE+offset);

                  (* read in the frame data *)
                  rc := Rofs.Read_file(fd,index,databuffer,size,bytesread);

                  IF rc = Rofs.Errors.NONE AND bytesread = size THEN
                    
                    WITH flibuffer = databuffer DO
                      Spy.Enter(flitimer);
                      Fli.fli_display_frame(fh, dpy, height, width,flibuffer,lsb);
                      Spy.Exit(flitimer);
                    END;

                  ELSE

                    Clib.Print("Could not read fli frame data.\n");
                    EXIT;

                  END;
                ELSE
                  Clib.Print("fli frame header incorrect.\n");
                  Fli.fli_dump(fh);
                  EXIT;
                END;
                END;
              ELSE
                Clib.Print("Could not read fli frame header.\n");
                EXIT;
              END;
            END; (* for *)
          ELSE
            Clib.Print("Could not read fli file header.\n");
          END;
        END;
      END;
      Rofs.Close_file(fd);
      Video.video_dealloc(dpy);
    ELSE
      Clib.Print("Could not open fli file.\n");
    END;
  END load1; 


BEGIN
  flitimer := Spy.Create("fli display frame");
END FliClient1. 
