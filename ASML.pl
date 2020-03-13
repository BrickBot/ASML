#!/bin/perl


# Global Perl Variables

# Default Values 
$clocktick=50;
$light = 50;
$dark = 40;  

print "******************************************************\n";
print "*   ASM State Chart Language for the Lego Mindstorm  *\n";
print "*                                                    *\n";
print "*       Developed at Wright State University         *\n";
print "*                  (c) 2001 MJJ Inc.                 *\n";
print "******************************************************\n\n";


#$filename = @ARGV[0];                       #input file argument 1
#$filename = "c:\\perl\\lego\\text.txt";     #input file hard-coded
#$filename = "text.txt";
print "Please enter name of input file\n";
$filename = <STDIN>;
chomp($filename);

#$outfile = $ARGV[1];                        # output file argument 2
#$outfile = "c:\\perl\\lego\\LASM-P1.txt";   # output file hard-coded
print "Please enter name of output file\n";
$outfile = <STDIN>;
chomp($outfile);

%state = undef;
%decision = undef;

@inputlines = &removeComments;
@commands = &getCommands(@inputlines);
@decisionlines = &getDecisionLines;
@statelines = &getStateLines;


@mealylines = &getMealyLines;
@varlist = &getVarList;

&checkVars;
@sensorlist = &getSensorList;
&checkSensors;
&createState;
&createDecision;
&createMealy;
&checkDestinations;
&checkDuplicates;


###########################################################
#This function opens the input file and copies all input  #
#commands into an array which is eventually returned.     # 
#It examines each line and drops all comments.            #
###########################################################
sub removeComments
{  
   local(@temptokens);     #local temporary array
   local(@returnlines);    #local temproary array 
#   local($filename);
   local($line);

   #opens the input file
#   $filename = @ARGV[0];
#   $filename = "c:\\perl\\lego\\text.txt";
 
   open(OUT, $filename) || die "Can't open $filename\n";
   
   #loops through each line of the input file 
   while(<OUT>)
   {
      $line = $_;
      #checks if current line contains a %, the comment symbol
      if($line =~ /%/)
      {
         chomp($line);
         #ignore any line that begins with a %
         if($line =~ /^%/)
         {
            next;
         }
         #ignore any code that comes after a % on the current line
         else 
         {
            @temptokens = split(/%/, $line);
            $line = @temptokens[0];
            if(($line !~ /,/) && ($line !~ /:/) && ($line !~ /{.*}/) &&
               ($line !~ /#/) && ($line !~ /&/) && ($line !~ /;/))
            {
               die "Error --$line\nMissing key character\n";
            }
            @returnlines = (@returnlines, $line);
         }
      }

      #this code handles all lines that do not have a %
      else
      {
         $line = $_;
         if($line =~ /^\n/)
         {
            next;
         }
         chomp($line);
         if($line =~ /;\s*;/)
         {
            die "Error -- $line\nIllegal format ;;\n";
         }
         if(($line !~ /:/) && ($line !~ /;/) && ($line !~ /{.*}/) &&
            ($line !~ /,/) && ($line !~ /#/) && ($line !~ /&/))
         {
            die "Error -- $line\nMissing key character\n";
         }
         #copies all relevant lines into the @returnlines array
         @returnlines = (@returnlines, $line);
      }
   }
   close(OUT);
   #returns @returnlines
   @returnlines;
}      

############################################################
#This function manipulates the array that is passed to it. # 
#It removes all whitespace from the individual strings.    #
#then merges all of the strings together and resplits them #
#according to the characters. 				   #
############################################################
sub getCommands
{
   local(@temparray);   #local variable that is returned
   local($templine);    #local string 

   @temparray = @_;     #copies the input array into @temparray

   #merges the entire input file into one line
   $templine = join("", @temparray);
   #splits the input file on all whitespace 
   @temparray = split(/\s*/, $templine);
   #joins the new spaceless tokens together
   $templine = join("", @temparray);
   #splits the string on ;, the end of command character
   @temparray = split(/;/, $templine);
   #returns the array of commands
   @temparray;
}


#############################################################
#This function gets all of the input lines that have the    #
#key characters needed for decision box code.  It checks    #
#these lines for syntax errors and ends the program if it   #
#finds any.                                                 #
#############################################################

sub getDecisionLines
{
   local($i);
   local($templine);
   local(@returnarray);
   
   $i = 0;
   
   while(@commands[$i])
   {
      $templine = @commands[$i];
      
      if(($templine =~ /:if/) || ($templine =~ /\(.*\)/) ||
         ($templine =~ /then/) || ($templine =~ /else/))
      {   
         #if statements that check for syntax errors
         if($templine !~ /\(.+\)/)
         {
            die "Error -- $templine\nMissing logical expression\n";
         }
         elsif($templine =~ /^if\(/)
         {
            die "Error -- $templine\nMissing decision box name\n";
         }
         elsif(($templine =~ /#/) || ($templine =~ /&/) ||
               ($templine =~ /,/) || ($templine =~ /~/))
         {
            die "Error -- $templine\nIllegal character on line\n";
         }
         elsif(($templine !~ /then->/) || ($templine !~ /else->/))
         {
            die "Error -- $templine\nMissing then-> or else-> statement\n";
         }
         elsif($templine !~ /.+:if\(.+\)then->.+else->.+/)
         {
            print "Error -- $templine\nError in structure\n";
	    print "Usage:\n";
	    die "<Name>: if{<expression>} then->{<dest>} else->{<dest>};\n";
         }
	 
	 elsif(($templine =~ /\(.*\(/) || ($templine =~ /\).*\)/))
	 {
	    die "Error -- $templine\nToo many braces on line\n";
	 }
	       
         
         elsif(($templine =~ /->.*:/) || ($templine =~ /->.*\(/) ||
               ($templine =~ /->.*\)/) || ($templine =~ /->.*~/))
         {
            die "Error -- $templine\nMissing ;\n";
         } 
         elsif($templine =~ /->.*->.*->/)
         {
            die "Error -- $templine\nToo many destinations\n";
         } 
         else
         {
	   #if no errors, return the array of decisionlines
            @returnarray = (@returnarray, $templine);
         }
      }
   $i = $i + 1;   
   }
   @returnarray;
}      



#############################################################
#This function gets all of the input lines that have the    #
#: character.  It checks these lines for syntax errors and  #
#ends the program if it finds any.                          #
#############################################################

sub getStateLines
{
   local($i);
   local($templine);
   local(@returnarray);
   
   $i = 0;
   
   while(@commands[$i])
   {
      $templine = @commands[$i];
      
      #checks each line for a valid key character
      if(($templine !~ /:/) && ($templine !~ /#/) &&
         ($templine !~ /&/) && ($templine !~ /{.*}/) &&
	 ($templine !~ /~/) && ($templine !~ /if/) &&
	 ($templine !~ /else/) && ($templine !~ /then/))
      {
         die "Error -- $templine\nMissing key character\n";
      } 
      if(($templine =~ /:/) && ($templine !~ /if/) && 
         ($templine !~ /{.*}/) && ($templine !~ /else/) &&
	 ($templine !~ /then/))
      {
         #if statements check each line for errors
         if($templine =~ /^:/)
         {
            die "Error -- $templine\nMissing state name\n";
         }
         elsif(($templine =~ /#/) || ($templine =~ /&/) ||
               ($templine =~ /{/) || ($templine =~ /}/) ||
	       ($templine =~ /~/))
         {
            die "Error -- $templine\nIllegal character in state line\n";
         }
         elsif(($templine !~ /,->\w+/) && ($templine !~ /:->/))
         {
            die "Error -- $templine\nMissing destination\n";
         }
         elsif(($templine =~ /->.*:/) || ($templine =~ /->.*{/) ||
               ($templine =~ /->.*}/) || ($templine =~ /->.*~/))
         {
            die "Error -- $templine\nMissing ;\n";
         }
         elsif($templine =~ /->.*->/)
         {
            die "Error -- $templine\nToo many destinations\n";
         }
         elsif(($templine =~ /::/) || ($templine =~ /:,/) ||
               ($templine =~ /,;/) || ($templine =~ /,,/))
         {
            die "Error -- $templine\nIllegal format in line\n";
         }
	 #fill the return array and return it
         else
         {
            @returnarray = (@returnarray, $templine);
         }
      }
   $i = $i + 1;
   }
   @returnarray;
}
      

#############################################################
#This function gets all of the input lines that have the    #
#~ character.  It checks these lines for syntax errors and  #
#ends the program if it finds any.                          #
#############################################################


sub getMealyLines
{
   local($i);
   local($templine);
   local(@returnarray);
   
   $i = 0;
   
   while(@commands[$i])
   {
      $templine = @commands[$i];
      
      if($templine =~ /~/)
      {
         #if statements to check for syntax errors
         if($templine =~ /^~/)
         {
            die "Error -- $templine\nMissing state name\n";
         }
         elsif(($templine =~ /#/) || ($templine =~ /&/) ||
               ($templine =~ /{/) || ($templine =~ /}/) ||
	       ($templine =~ /:/))
         {
            die "Error -- $templine\nIllegal character in mealy line\n";
         }
         elsif($templine !~ /,->\w+/)
         {
            die "Error -- $templine\nMissing destination\n";
         }
         elsif(($templine =~ /->.*:/) || ($templine =~ /->.*{/) ||
               ($templine =~ /->.*}/) || ($templine =~ /->.*~/))
         {
            die "Error -- $templine\nMissing ;\n";
         }
         elsif($templine =~ /->.*->/)
         {
            die "Error -- $templine\nToo many destinations\n";
         }
         elsif(($templine =~ /~~/) || ($templine =~ /~,/) ||
               ($templine =~ /,;/) || ($templine =~ /,,/))
         {
            die "Error -- $templine\nIllegal format in line\n";
         }
	 #if no errors, return the mealy array
         else
         {
            @returnarray = (@returnarray, $templine);
         }
      }
   $i = $i + 1;
   }
   @returnarray;
}


#######################################################
#This function retrieves the list of user-defined     #
#variables from the input file.  It returns the list. #      
#######################################################

sub getVarList
{
   local($i);
   local($templine);
   local($endflag);
   local(@temptokens);
   local(@returnarray);
   local($lightflag);
   local($darkflag);
   
   $i = 0;
   $endflag = 0;
   $lightflag = 0;
   $darkflag = 0;

   while(@commands[$i])
   {
      $templine = @commands[$i];
      #enforce that the variables must be at top of file
      if(($templine =~ /:/) || ($templine =~ /{/))
      {
         $endflag = 1;
      }
      #only interested in variables that begin with #
      if($templine =~ /#/)
      {
         if($templine !~ /^#/)
         {
            die "Error -- $templine\n# must begin line\n";
         }
         elsif(($templine =~ /:/) || ($templine =~ /{/) ||
               ($templine =~ /&/) || ($templine =~ /#.*#/))
         {
            die "Error -- $templine\nMissing ;\n";
         }
         elsif(($templine =~ /#,/) || ($templine =~ /#;/) ||
               ($templine =~ /,;/) || ($templine =~ /,,/))
         {
            die "Error -- $templine\nMissing argument\n";
         }
         elsif($endflag == 1)
         {
            die "Error -- $templine\n# statements must begin file\n";
         }
         if(($templine =~ /^#CLOCK=/) || ($templine =~ /^#clock=/) || ($templine =~ /^#Clock=/))
         {
            @temptokens = split(/=/, $templine);
            if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
            {
               die "Error -- Illegal value for clock tick\n";
            }
            $clocktick = @temptokens[1];
         }
	 elsif($templine =~ /^#CLOCK[0-9]/)
	 { 
	    @temptokens = split(/K/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for CLOCK\n";
	    }
	    $clocktick = @temptokens[1];  
	 }
	 elsif(($templine =~ /^#clock[0-9]/) || ($templine =~ /^#Clock[0-9]/))
	 { 
	    @temptokens = split(/k/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for clock\n";
	    }
	    $clocktick = @temptokens[1];  
	 }
         
	 elsif(($templine =~ /^#LIGHT=/) || ($templine =~ /^#light=/) || ($templine =~ /^#Light=/))
         {
            @temptokens = split(/=/, $templine);
            if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
            {
               die "Error -- Illegal value for LIGHT\n";
            }
            $light = @temptokens[1];
            $lightflag = 1;
         }

         elsif($templine =~ /^#LIGHT[0-9]/)
	 { 
	    @temptokens = split(/T/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for LIGHT\n";
	    }
	    $light = @temptokens[1]; 
            $lightflag = 1; 
	 }
	 
	 elsif(($templine =~ /^#light[0-9]/) || ($templine =~ /^#Light[0-9]/))
	 { 
	    @temptokens = split(/t/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for LIGHT\n";
	    }
	    $light = @temptokens[1]; 
            $lightflag = 1; 
	 }

	 elsif(($templine =~ /^#DARK=/) || ($templine =~ /^#dark=/) || ($templine =~ /^#Dark=/))
         {
            @temptokens = split(/=/, $templine);
            if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
            {
               die "Error -- Illegal value for DARK\n";
            }
            $dark = @temptokens[1];
            $darkflag = 1;
         }

         elsif($templine =~ /^#DARK[0-9]/)
	 { 
	    @temptokens = split(/K/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for DARK\n";
	    }
	    $dark = @temptokens[1]; 
            $darkflag = 1; 
	 }
	 
	 elsif(($templine =~ /^#dark[0-9]/) || ($templine =~ /^#Dark/))
	 { 
	    @temptokens = split(/k/, $templine);
	    if((@temptokens[1] =~ /[a-zA-Z]/) || (@temptokens[1] =~ /\W/))
	    {
	       die "Error -- Illegal value for DARK\n";
	    }
	    $dark = @temptokens[1]; 
            $darkflag = 1; 
	 }

         else
         {
            @temptokens = split(/#/, $templine);
            $templine = @temptokens[1];
            @temptokens = split(/,/, $templine);
            @returnarray = (@returnarray, @temptokens);
         }
      }
   $i = $i + 1;
   }

   if(($lightflag == 1) || ($darkflag == 1))
   {
      if(($lightflag == 0) || ($darkflag == 0))
      {
          die "Error - Need to specify both light and dark threshholds\n";
      } 
      if($light <= $dark)
      {
          print "Light is $light and Dark is $dark\n";
          die "Error - light threshhold must be greater than dark threshhold\n";
      } 
      if($light > 100)
      {
          die "Error - light threshhold must not be greater than 100\n";
      }
      if($dark < 0)
      {
          die "Error - dark threshhold must be greater than 0\n";
      }
      
      @returnarray = (@returnarray, "LIGHT");
      @returnarray = (@returnarray, "DARK");

   }
   if($clocktick <= 0)
   {
      die "Error -- CLOCK value must be positive\n";
   }
   @returnarray;
}


############################################################
#This function gets the sensor list from the input file.   #
#It returns the list of sensors in an array.               #
############################################################

sub getSensorList
{
   local($i);
   local($endflag);
   local(@temptokens);
   local($templine);
   local(@returnarray);

   $i = 0;
   $endflag = 0;

   while(@commands[$i])
   {
      #enforce the fact that sensors must be declared at top
      $templine = @commands[$i];
      if(($templine =~ /:/) || ($templine =~ /{/))
      {
         $endflag = 1;
      }
      #only interested in lines that have the & character
      if($templine =~ /&/)
      {
         if($templine !~ /^&/)
         {
            die "Error -- $templine\nIllegal use of &\n";
         }
         elsif(($templine =~ /:/) || ($templine =~ /{/) || 
               ($templine =~ /#/) || ($templine =~ /&.*&/))
         {
            die "Error -- $templine\nMissing ;\n"; 
         }
         elsif(($templine =~ /&,/) || ($templine =~ /&;/)||
               ($templine =~ /,;/) || ($templine =~ /,,/))
         {
            die "Error -- $templine\nMissing argument\n";
         }
         elsif($endflag == 1)
         {
            die "Error -- $templine\n& statements must begin file\n";
         }
         else
         {
            @temptokens = split(/&/, $templine);
            $templine = @temptokens[1];
            @temptokens = split(/,/, $templine);
            @returnarray = (@returnarray, @temptokens);
         }
      }

   $i = $i + 1;
   }
   @returnarray;  
}


#############################################################
#This function creates the structure that parses each state #
#line.  It is used by later code to create the LASM file.   #
#The function also creates useful global arrays.            #
#############################################################
sub createState
{
   local($templine);
   local($templine2);
   local($i);
   local($j);
   local(@temptokens);
   local(@temptoks);
   local(@currtoks);
   
   $i = 0;
   while(@statelines[$i])
   {
      $templine = @statelines[$i];
      @temptokens = split(/:/, $templine);
      $templine = @temptokens[0];
      @statenames = (@statenames, $templine);
      $state{@statenames[$i]}{name} = $templine;
      $templine = @temptokens[1];
      @temptokens = split(/,/, $templine);
      $j = 0;
      while(@temptokens[$j])
      {
         $templine = @temptokens[$j];
         if($templine =~ /->/)
         {
            @temptoks = split(/->/, $templine);
            $state{@statenames[$i]}{destination} = @temptoks[1];
            @stateDestinations = (@stateDestinations, @temptoks[1]);
         }
         else
         {
            @currtoks = (@currtoks, $templine);
         }
         $j = $j + 1;
      }
      $j = 0;
      while(@currtoks[$j])
      {
         $state{@statenames[$i]}{value}[$j] = @currtoks[$j];
         $j = $j + 1;
      }
      $j = 0;
      while(@currtoks[$j])
      {
         delete @currtoks[$j];
         $j = $j + 1;
      }

      $i = $i + 1;
      
   }
}


############################################################
#This function creates the structure for the fully parsed  #
#decision lines.  This structure is useful later when we   #
#create the LASM file.	It also creates other useful       #
#global arrays.						   #
############################################################
sub createDecision
{
   local($templine);
   local($templine2);
   local($i);
   local($j);
   local(@temptokens);
   local(@temptoks);
   local(@temptoks2);
  
   $i = 0;
   while(@decisionlines[$i])
   {
      
      @temptokens = split(/:/, @decisionlines[$i]);
      $templine = @temptokens[0];
      @decisionnames = (@decisionnames, $templine);
      $decision{@decisionnames[$i]}{name} = @decisionnames[$i];
      @temptokens = split(/else->/, @decisionlines[$i]);
      $templine = @temptokens[1];
      $decision{@decisionnames[$i]}{zero} = $templine;
      @decisionDestinations = (@decisionDestinations, $templine);
      $templine = @temptokens[0];
      @temptokens = split(/\)then->/, $templine);
      $templine = @temptokens[1];
      @decisionDestinations = (@decisionDestinations, $templine);
      $decision{@decisionnames[$i]}{one} = $templine;
      $templine = @temptokens[0];
      @temptokens = split(/\(/, $templine);
      $templine = @temptokens[1];
      $decision{@decisionnames[$i]}{expression} = $templine;
      
      $i = $i + 1;
   }   
}


##############################################################
#This function creates the mealy structure that will be      #
#useful later when we create the LASM code.  It also creates #
#other useful global arrays.			 	     #		
##############################################################

sub createMealy
{
   local($templine);
   local($templine2);
   local($i);
   local($j);
   local(@temptokens);
   local(@temptoks);
   local(@currtoks);
   
   $i = 0;
   while(@mealylines[$i])
   {
      $templine = @mealylines[$i];
      @temptokens = split(/~/, $templine);
      $templine = @temptokens[0];
      @mealynames = (@mealynames, $templine);
      $mealy{@mealynames[$i]}{name} = $templine;
      $templine = @temptokens[1];
      @temptokens = split(/,/, $templine);
      $j = 0;
      while(@temptokens[$j])
      {
         $templine = @temptokens[$j];
         if($templine =~ /->/)
         {
            @temptoks = split(/->/, $templine);
            $mealy{@mealynames[$i]}{destination} = @temptoks[1];
            @mealyDestinations = (@mealyDestinations, @temptoks[1]);
         }
         else
         {
            @currtoks = (@currtoks, $templine);
         }
         $j = $j + 1;
      }
      $j = 0;
      while(@currtoks[$j])
      {
         $mealy{@mealynames[$i]}{value}[$j] = @currtoks[$j];
         $j = $j + 1;
      }
      $j = 0;
      while(@currtoks[$j])
      {
         delete @currtoks[$j];
         $j = $j + 1;
      }

      $i = $i + 1;
      
   }
}


############################################################
#This function checks each of the destinations to make sure#
#that each is a valid name of a state, decision, or mealy  #
#box.  The program dies if a bad name is discovered.       #
############################################################
sub checkDestinations
{
   local($i);
   local($j);
   local(@scheck);
   local(@dcheck);
   local(@mcheck);
   local($error);
   
   @scheck = (@scheck, @statenames);
   @scheck = (@scheck, @decisionnames);
   @dcheck = (@dcheck, @statenames);
   @dcheck = (@dcheck, @decisionnames);
   @dcheck = (@dcheck, @mealynames);
   @mcheck = @scheck;
   
   
   $i = 0;
   $error = "true";
   while(@stateDestinations[$i])
   {
      $error = "true";
      $j = 0;
      while(@scheck[$j])
      {
         if(@stateDestinations[$i] eq @scheck[$j])
	 {
	    $error = "false";
	 }
	 $j = $j + 1;
      }
      if($error eq "true")
      {
         print "Error -- $stateDestinations[$i]\nInvalid Destination\n";
	 print "Please check that destination isn't mispelled and\n";
	 print "state destination isn't a mealy name\n";
	 die "Exiting\n";
      }
      $i = $i + 1;   
   }#end state dest code

   $i = 0;
   $error = "true";
   while(@decisionDestinations[$i])
   {
      $error = "true";
      $j = 0;
      while(@dcheck[$j])
      {
         if(@decisionDestinations[$i] eq @dcheck[$j])
	 {
	    $error = "false";
	 }
	 $j = $j + 1;
      }
      if($error eq "true")
      {
         print "Error -- $decisionDestinations[$i]\nInvalid Destination\n";
	 die "Please check that destination isn't mispelled.\n";
      }
      $i = $i + 1;   
   }#end decision dest code

   $i = 0;
   $error = "true";
   while(@mealyDestinations[$i])
   {
      $error = "true";
      $j = 0;
      while(@mcheck[$j])
      {
         if(@mealyDestinations[$i] eq @mcheck[$j])
	 {
	    $error = "false";
	 }
	 $j = $j + 1;
      }
      if($error eq "true")
      {
         print "Error -- $mealyDestinations[$i]\nInvalid Destination\n";
	 print "Please check that destination isn't mispelled and that\n";
	 print "all mealy boxes are combined\n";
	 die "Exiting\n";
      }
      $i = $i + 1;   
   }#end mealy dest code

}#end checkDestinations
############################################################
#This function checks the list of sensors for errors or for#
#duplicates.						   #
############################################################
sub checkSensors
{
   local($i);
   $i = 0;

   while(@sensorlist[$i])
   {
      if((@sensorlist[$i] ne "T1") && (@sensorlist[$i] ne "T2") &&
         (@sensorlist[$i] ne "T3") && (@sensorlist[$i] ne "L1") &&
         (@sensorlist[$i] ne "L2") && (@sensorlist[$i] ne "L3"))
      {
         die "Error -- @sensorlist[$i] is not a valid sensor value\n";
      }
      $i = $i + 1;
   } 
}


############################################################
#This function checks the list of variables to make sure   #
#that each one has a valid name.			   #
############################################################

sub checkVars
{
   local($i);
   $i = 0;
   
   while(@varlist[$i])
   {
      if(@varlist[$i] =~ /^[0-9]/)
      {
         die "Error -- @varlist[$i]\nVariable can't start with digit\n";
      }
      $i = $i + 1;
   }
}


##############################################################
#This function checks each of the names of the mealy, state, #
#and decision boxes for duplicates.  It also makes sure that #
#no variable names are repeated.                             #
##############################################################
sub checkDuplicates
{
   local($i);
   local($j);
   local($count);
   local($line);

   $i = 0;
   $j = 0;
   while(@statenames[$i])
   {
      $count = 0;
      $line = @statenames[$i];
      #check each state name with state names
      $j = 0;
      while(@statenames[$j])
      {
         if($line eq @statenames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each state name with decision names
      $j = 0;
      while(@decisionnames[$j])
      {
         if($line eq @decisionnames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each state name with mealy names
      $j = 0;
      while(@mealynames[$j])
      {
         if($line eq @mealynames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      if($count != 1)
      {
         die "Error -- $line is used in more than one name\n";
      }
      $i = $i + 1;
   }

   $i = 0;
   while(@decisionnames[$i])
   {
      $count = 0;
      $line = @decisionnames[$i];
      #check each decision name with state names
      $j = 0;
      while(@statenames[$j])
      {
         if($line eq @statenames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each decision name with decision names
      $j = 0;
      while(@decisionnames[$j])
      {
         if($line eq @decisionnames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each decision name with mealy names
      $j = 0;
      while(@mealynames[$j])
      {
         if($line eq @mealynames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      if($count != 1)
      {
         die "Error -- $line is used in more than one name\n";
      }
      $i = $i + 1;
   }   
   $i = 0;
   while(@mealynames[$i])
   {
      $count = 0;
      $line = @mealynames[$i];
      #check each mealy name with state names
      $j = 0;
      while(@statenames[$j])
      {
         if($line eq @statenames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each mealy name with decision names
      $j = 0;
      while(@decisionnames[$j])
      {
         if($line eq @decisionnames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      #check each mealy name with mealy names
      $j = 0;
      while(@mealynames[$j])
      {
         if($line eq @mealynames[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      if($count != 1)
      {
         die "Error -- $line is used in more than one name\n";
      }
      $i = $i + 1;
   }   
   #check if single sensor is used more than once
   $line = join("", @sensorlist);
   if(($line =~ /1.*1/) || ($line =~ /2.*2/) || ($line =~ /3.*3/))
   {
      die "Error -- sensor list\nDuplicate sensors\n";
   }  

   $i = 0;
   while(@varlist[$i])
   {
      $line = @varlist[$i];
      $count = 0;
      $j = 0;
      while(@varlist[$j])
      {
         if($line eq @varlist[$j])
         {
            $count = $count + 1;
         }
         $j = $j + 1;
      }
      if($count != 1)
      {
         die "Error -- $line is duplicated in variable list\n";
      }
      $i = $i + 1;
   }
}



#######################################################
#This function is merely a support function to recurse#
#through all the possible functions of a state and    #
#make an array of the various boxes encountered.      #
#######################################################

sub recurse
{
   local($currname);
   local($check);
   local(@inputarray);
   local($j);
   
   $j = 0;
   while(@plist[$j])
   {
      if($j > 250)
      {
         die "Error -- loop in ASM chart\n";
      }
      $j = $j + 1;
   }

   @inputarray = @_;
   $currname = @inputarray[0];
   $check = &compare($currname);

   #base case is when the current box is state box
   if($check eq "s")
   {
      @plist = (@plist, $currname);
   }

   #processes mealy box
   elsif($check eq "m")
   {
      @plist = (@plist, $currname);
      &recurse($mealy{$currname}{destination});
   }

   #processes decision box
   else
   {
      @plist = (@plist, $currname);
      @plist = (@plist, "zero");
      &recurse($decision{$currname}{zero});
      @plist = (@plist, $currname);
      @plist = (@plist, "one");
      &recurse($decision{$currname}{one});
   }
}


#####################################################
#This function is a support function that determines#
#if a string is a state name, a decision name, or a #
#mealy name                                         #
#####################################################
sub compare
{
   local($temp);
   local($i);
   local($result);
   $temp = @_[0];



   $i = 0;
   while(@statenames[$i])
   {
      if($temp eq @statenames[$i])
      {
         $result = "s";
      }
      $i = $i + 1;
   }
   $i = 0;
   while(@decisionnames[$i])
   {

      if($temp eq @decisionnames[$i])
      {
         $result = "d";
      }
      $i = $i + 1;
   }
   $i = 0;
   while(@mealynames[$i])
   {
      if($temp eq @mealynames[$i])
      {
         $result = "m";
      }
      $i = $i + 1;
   }
   $result;
}


######################################################
#This function is a support function that creates two#
#global arrays that are useful in the processing of  #
#mealy boxes coming from a various state.            #    
######################################################

sub makepath
{
   local($i);
   local($j);
   local($k);
   local($comp);
   local(@decs);
   local($arg);
   local($returnstring);
   
   
   $arg = @_[0];
   $returnstring = "0";
   
   #delete a global array
   $i = 0;
   while(@plist[$i])
   {
      pop(@plist);
   }
   
   
   
   @plist = (@plist, $arg);
   #call recurse to get the path from the current state
   &recurse($state{$arg}{destination});
   
   
   #delete global arrays
   $i = 0;
   while(@TMEALY[$i])
   {
      pop(@TMEALY);
   }

   $i = 0;
   while(@TMEALYI[$i])
   {
      pop(@TMEALYI);
   }

   $i = 1;
   $j = 1;
   #collect the decision names coming from the state
   while(@plist[$i])
   {
      $comp = &compare(@plist[$i]);
      if($comp eq "d")
      {
         if(@plist[$i+1] eq "zero")
         {
            @decs = (@decs, @plist[$i]);
         }
      }
      $i = $i + 1;
   }

   @TMEALY = (@TMEALY, $arg);
   @TMEALYI = (@TMEALYI, "-");
   $i = 0;
   while(@decs[$i])
   {
      @TMEALY = (@TMEALY, "-");
      @TMEALY = (@TMEALY, "-");
      @TMEALY = (@TMEALY, "-");
      @TMEALYI = (@TMEALYI, "-");
      @TMEALYI = (@TMEALYI, "-");
      @TMEALYI = (@TMEALYI, "-");
      $i = $i + 1;
   }
   
   
   #build the @TMEALY and @TMEALYI arrays
   $i = 0;
   $j = 1;
   while(@decs[$i])
   {
      @TMEALY[$j] = @decs[$i];
      $k = 0;
      while(@decisionnames[$k])
      {
         if(@decs[$i] eq @decisionnames[$k])
	 {
	
	    @TMEALYI[$j] = $k;
	 }
	 $k = $k + 1;
      }
      $j = $j + 1;
      
      #find all the mealy names in the paths
      $check = &compare($decision{@decs[$i]}{zero});
      if($check eq "m")
      {
         $returnstring = "1";
         @TMEALY[$j] = $decision{@decs[$i]}{zero};
	 
	 $k = 0;
	 while(@mealynames[$k])
	 {
	    if($decision{@decs[$i]}{zero} eq @mealynames[$k])
	    {
	       @TMEALYI[$j] = $k;
	    }
	    $k = $k + 1;
         }
      }
      $j = $j + 1;
      
      $check = &compare($decision{@decs[$i]}{one});
      if($check eq "m")
      {
         $returnstring = "1";
         @TMEALY[$j] = $decision{@decs[$i]}{one};
	 $k = 0;
	 while(@mealynames[$k])
	 {
	    if($decision{@decs[$i]}{one} eq @mealynames[$k])
	    {
	       @TMEALYI[$j] = $k;
	    }
	    $k = $k + 1;
         }
      }
      $j = $j + 1;
      $i = $i + 1;
   }
   
  $returnstring;
}

#######################################################################################


###########################
# State Box Handling Code #
###########################

#$outfile = $ARGV[1];
#$outfile = "LASM-P1.txt";
$openout = ">".$outfile;

open(OUTF,$openout) || 
    die "\nERROR : Output file '$outfile' could not be created\n";

print OUTF "// $outfile - Created using ASML for the Lego Mindstorm. \n";
print OUTF "//            Developed at WSU (c) 2001 MJJ Inc. \n\n"; 

print OUTF "task 0\n";

initVars();
initSensors();

print OUTF "\n// -- State Boxes --\n";

for($i=0; @statenames[$i] ne undef; $i++)
{
 $statenum = $i+1;
 print "State : $state{@statenames[$i]}{name} is shown as $statenum\n";

 print OUTF "$state{@statenames[$i]}{name}:\n";
 print OUTF "disp 0,2,$statenum \n";

 for($j=0; $state{@statenames[$i]}{value}[$j] ne undef; $j++)
 {
   $execOp = 0; # flag to see if operation executed (compiled)

  # This code will first split the command by motor letter A B and C
  # If the letter is found, it will look at the remainder of the split to do
  # compilation.
  
  ###########
  # Motor A #
  ###########
   @hold = split(/A/,$state{@statenames[$i]}{value}[$j]); #check all things with A

   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {
    if ($hold[1] eq "on")    {$execOp=1;
	                          print OUTF "out 2,1\n";}
    if ($hold[1] eq "off")   {$execOp=1;
	                          print OUTF "out 1,1\n";}
    if ($hold[1] eq "float") {$execOp=1;
	                          print OUTF "out 0,1\n";}
    if ($hold[1] eq "f")     {$execOp=1;
	                          print OUTF "out 2,1\n";
	                          print OUTF "dir 2,1\n";}
    if ($hold[1] eq "b")     {$execOp=1;
	                          print OUTF "out 2,1\n";
	                          print OUTF "dir 0,1\n";}
	if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")   
	                         {$execOp=1;
	                          print OUTF "pwr 1,2,$hold[1] \n";}
   }

  ###########
  # Motor B #
  ###########
  if($execOp == 0)
  {
   @hold = split(/B/,$state{@statenames[$i]}{value}[$j]); #check all things with B

   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {
    if($hold[1] eq 'on')    {$execOp=1;
	                         print OUTF "out 2,2\n";}
    if($hold[1] eq 'off')   {$execOp=1;
	                         print OUTF "out 1,2\n";}
    if($hold[1] eq 'float') {$execOp=1;
	                         print OUTF "out 0,2\n";}
    if($hold[1] eq 'f')     {$execOp=1;
	                         print OUTF "out 2,2\n";
	                         print OUTF "dir 2,2\n";}
    if($hold[1] eq 'b')     {$execOp=1;
	                         print OUTF "out 2,2\n";
	                         print OUTF "dir 0,2\n";}
    if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")  
	                        {$execOp=1;
	                         print OUTF "pwr 2,2,$hold[1] \n";}
   }
  }

  ###########
  # Motor C #
  ###########
  if($execOp==0)
  {
   @hold = split(/C/,$state{@statenames[$i]}{value}[$j]); #check all things with C 

   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {
    if($hold[1] eq 'on')    {$execOp=1;
	                         print OUTF "out 2,4\n"};
    if($hold[1] eq 'off')   {$execOp=1;
	                         print OUTF "out 1,4\n"};
    if($hold[1] eq 'float') {$execOp=1;
	                         print OUTF "out 0,4\n"};
    if($hold[1] eq 'f')     {$execOp=1;
	                         print OUTF "out 2,4\n";
	                         print OUTF "dir 2,4\n";}
    if($hold[1] eq 'b')     {$execOp=1;
	                         print OUTF "out 2,4\n";
	                         print OUTF "dir 0,4\n";}
    if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")  
	                        {$execOp=1;
	                         print OUTF "pwr 4,2,$hold[1] \n";}
   }
  }

  ###########
  # Sounds  #
  ###########
  if($execOp==0)
  {
   @hold = split(/sound/,$state{@statenames[$i]}{value}[$j]); #check all things with sound

   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {
    if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || 
	   $hold[1] eq "3" || $hold[1] eq "4" || $hold[1] eq "5")  
	{
    $execOp=1;
	print OUTF "plays $hold[1] \n";
    }
   }
  }


  #####################################################
  # Assignment  FORM : VAR <- VAR [operator] CONSTANT #
  ##################################################### 
  if($execOp==0)
  {
   @hold = split(/<-/,$state{@statenames[$i]}{value}[$j]); #check for variable assignment
   
   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {  
    assign($hold[0],$hold[1],$state{@statenames[$i]}{name});
    $execOp=1;
   }
  }
 
  if($execOp==0)
  {
   die "\nERROR: Unrecognized command $state{@statenames[$i]}{value}[$j] in state $state{@statenames[$i]}{name}\n";
  }
 } # end of commands loop

 # check for Mealy outputs
 $mealycheck = makepath($state{@statenames[$i]}{name});

 if ($mealycheck > 0) # 1 or more Mealy outputs
 {  
   createMealyState(); }
 else
 {
  print OUTF "wait 2,$clocktick\n";
  print OUTF "jmpl $state{@statenames[$i]}{destination}\n\n";
 }
} # end state box


#####################################################
## Mealy Box Handling Code (Moore-Based Execution) ##
#####################################################

if($mealynames[0] ne undef)
{ print OUTF "// -- Mealy Boxes (Moore Execution) --\n";}

for($i=0; $mealynames[$i] ne undef; $i++)
{
 print OUTF "$mealy{@mealynames[$i]}{name}:\n";

 for($n=0; $mealy{@mealynames[$i]}{value}[$n] ne undef; $n++)
 {
  @mealyops[$n] = $mealy{@mealynames[$i]}{value}[$n];
  }

 mealyCommands(@mealyops);

 print OUTF "jmpl $mealy{@mealynames[$i]}{destination}\n\n";
} # end mealy box 


################################
## Decision Box Handling Code ##
################################
print OUTF "// -- Decision Boxes --\n";

for($i=0; $decisionnames[$i] ne undef; $i++)
{
 print OUTF "$decision{@decisionnames[$i]}{name}:\n";
 
 ##########################################################
 # check if expression is a single sensor or a comparison #
 # varDecBox() will handle comparison                     # 
 ##########################################################

 $chksen = checkSensor($decision{@decisionnames[$i]}{expression},
                       $decision{@decisionnames[$i]}{name});
 
 if($chksen == 1)
 { 
   $sens = sensorValue($decision{@decisionnames[$i]}{expression},
                       $decision{@decisionnames[$i]}{name});
    
#check for light sensor  
   if($decision{@decisionnames[$i]}{expression} eq "L1" || 
      $decision{@decisionnames[$i]}{expression} eq "L2" ||
	  $decision{@decisionnames[$i]}{expression} eq "L3")
   {
    print OUTF "chkl 0,LIGHT,0,9,$sens,$decision{@decisionnames[$i]}{name}" . "_1\n";
   }
   else
     {
      print OUTF "chkl 2,1,2,9,$sens,$decision{@decisionnames[$i]}{name}" . "_1\n";
     }
  }
  else{
        varDecBox($decision{@decisionnames[$i]}{expression},
                       $decision{@decisionnames[$i]}{name});
	  }
    
   print OUTF "jmpl $decision{@decisionnames[$i]}{one} \n";

   print OUTF $decision{@decisionnames[$i]}{name} . "_1: \n";
   print OUTF "jmpl $decision{@decisionnames[$i]}{zero} \n\n";

} # end decision box

print OUTF "endt";
print "Successfully Compiled!!!\n\n Hit Enter to Exit.";
$wait = <STDIN>;


#################
## Subroutines ##
#################


##########################################################
# assign(variable,expression,state) -                    # 
#                        function handles any assignment #
#                                                        #
#   variable - variable receiving value                  #
#   expression - math expression in form var1 + const or #
#                                        var1 + var2  or #
#                                        var1 or const   #      
##########################################################
sub assign
{
 my(@ahold);
 my($ret);     # 1 = variable found or constant
 my($source);  # 0 = variable  2 = constant

 $ret = checkVar($_[0]);
 if($ret == 0){ error($_[0],1,$_[2]); }

  ############ 
  # Addition # 
  ############

  @ahold = split(/\+/,$_[1]);
 
  if ($ahold[0] ne $_[1])
  {
   if($ahold[0] ne $_[0])
   {
    $ret = checkVar($ahold[0]);
	if($ret == 0){error($ahold[0],1,$_[2]);}
     
	$source = 0;
    if($ahold[0] =~ /^[0-9]/) {$source = 2; }

	print OUTF "setv $_[0],$source,$ahold[0]\n";
   }
   
   if($ahold[1] eq undef)
   {
    die "Error in assignment operation $_[0] $_[1] in state : $_[2] \n";
   }    

    $ret = checkVar($ahold[1]);
    if($ret == 0){ error($ahold[1],1,$_[2]); }
    
    $source = 0;
    if($ahold[1] =~ /^[0-9]/) {$source = 2; }

	print OUTF "sumv $_[0],$source,$ahold[1]\n";
   
   return;
  }

 ###############
 # Subtraction #
 ###############

  @ahold = split(/-/,$_[1]);

  if ($ahold[0] ne $_[1])
  {
   if($ahold[0] ne $_[0])
   {
    $ret = checkVar($ahold[0]);
	if($ret == 0){error($ahold[0],1,$_[2]);}
    
	$source = 0;
    if($ahold[0] =~ /^[0-9]/) {$source = 2; }
	
	print OUTF "setv $_[0],$source,$ahold[0]\n";
   }

   if($ahold[1] eq undef)
   {
    die "Error in assignment operation $_[0] $_[1] in state : $_[2] \n";
   }       

   $ret = checkVar($ahold[1]);
   if($ret == 0){error($ahold[1],1,$_[2]);}

   $source = 0;
   if($ahold[1] =~ /^[0-9]/) {$source = 2; }

   print OUTF "subv $_[0],$source,$ahold[1]\n";
    
  return;
 }
    
 ##################
 # Multiplication #
 ##################

 @ahold = split(/\*/,$_[1]);

 if ($ahold[0] ne $_[1])
 {
   if($ahold[0] ne $_[0])
   {
    $ret = checkVar($ahold[0]);
    if($ret == 0){error($ahold[0],1,$_[2]);}

    $source = 0;
    if($ahold[0] =~ /^[0-9]/) {$source = 2; }

    print OUTF "setv $_[0],$source,$ahold[0]\n";
   }
   
   if($ahold[1] eq undef)
   {
    die "Error in assignment operation $_[0] $_[1] in state : $_[2] \n";
   }       

   $ret = checkVar($ahold[1]);
   if($ret == 0){error($ahold[1],1,$_[2]);}

    $source = 0;
    if($ahold[1] =~ /^[0-9]/) {$source = 2; }

   print OUTF "mulv $_[0],$source,$ahold[1]\n";
     
  return;
 }
 
 ############
 # Division #
 ############

 @ahold = split(/\//,$_[1]);

 if ($ahold[0] ne $_[1])
 {
   if($ahold[0] ne $_[0])
   {
    $ret = checkVar($ahold[0]);
    if($ret == 0){error($ahold[0],1,$_[2]);}

    $source = 0;
    if($ahold[0] =~ /^[0-9]/) {$source = 2; }

    print OUTF "setv $_[0],$source,$ahold[0]\n";
   }
   
   if($ahold[1] eq undef)
   {
    die "Error in assignment operation $_[0] $_[1] in state : $_[2] \n";
   }       

   $ret = checkVar($ahold[1]);
   if($ret == 0){error($ahold[1],1,$_[2]);}

    $source = 0;
    if($ahold[1] =~ /^[0-9]/) {$source = 2; }

   print OUTF "divv $_[0],$source,$ahold[1]\n";
  
  return;
 }

 #################
 # Simple Assign #
 #################

 $ret = checkVar($_[1]);
 if($ret == 0){error($_[1],1,$_[2]);}

 $source = 0;
 if($_[1] =~ /^[0-9]/) {$source = 2; }

 print OUTF "setv $_[0],$source,$_[1]\n";
} 
# end assign


##################################################################
## error(arg,message,state) - will provide basic error handling ##
##                            and program termination.          ##
##  arg - argument where error was found                        ##
##  message - error message                                     ##
##  state - state where error was found                         ##
##                                                              ##  
## NOTE : all text must be included in the arguments. Calling   ##
##        error() will terminate with no output.                ##
##################################################################

sub error {

if ($_[1] == 1) {
 die "\n $_[0] Is Not Defined. Error in State : $_[2]\n";
 }

if ($_[1] == 2) {
  die "\n $_[0] Is An Invalid Command. Error in State : $_[2]\n";
  }

if ($_[1] == 3){
  die "\n Sytax Error in State $_[2]\n";
 }

die "\n $_[0] $_[1] $_[2]\n";
} #end error

##################################################################
## checkVar(variableName) - will check the variable list for    ##
##                          the name listed.                    ##
##   Returns : 1 - Variable Found                               ##
##             0 - Variable does not exist                      ##
##################################################################

sub checkVar{

my($checkVar);
$checkVar=0;

# check if variable is a numeric constant (starts with 0-9)
 if ($_[0]=~ /^[0-9]/) { return 1; }

 while(@varlist[$checkVar])
 {
  if ($_[0] eq $varlist[$checkVar])
   {return 1;}
  $checkVar++;
 }
  return 0;
} #end checkVar

#################################################################
## checkSensor(sensorName) - will check the sensor list for    ##
##                          the name listed.                   ##
##   Returns : 1 - Sensor Found                                ##
##             0 - Sensor does not exist                       ##
#################################################################

sub checkSensor{
my($checkSen);
$checkSen=0;

 while(@sensorlist[$checkSen])
 {
  if ($_[0] eq $sensorlist[$checkSen])
   {return 1;}
  $checkSen++;
 }
  return 0;
} #end checkSensor

###################################################################
## initSensors() - initializes all sensors from the sensor list. ##
##                 Must be run after sensor list is created to   ##
##                 have all sensors initialized at the beginning ##
##                 of the LASM program.                          ##
##                 Also checks for illegal sensor values.        ##
###################################################################

sub initSensors{
my($i);
my($sensor1);
my($sensor2);
my($sensor3);
my($sennum);
my($useLight);
my(@shold);

$useLight = 0;
$sensor1  = 0;
$sensor2  = 0;
$sensor3  = 0;

 if ($sensorlist[0] ne undef){
  print OUTF "\n// -- Sensor Definitions -- \n"; 
  }
 
 for ($i=0; $sensorlist[$i] ne undef; $i++)
 {

  if($sensorlist[$i] ne 'T1' && $sensorlist[$i] ne 'T2' &&
     $sensorlist[$i] ne 'T3' && $sensorlist[$i] ne 'L1' &&
	 $sensorlist[$i] ne 'L2' && $sensorlist[$i] ne 'L3')
  {
   print "\nERROR: Invalid Sensor Type : $sensorlist[$i]\n";
   die " -Must be Light (L) or Touch (T) on Ports (1-3) \n";
  }  


 ######################################
 # Touch Sensor - Switch Boolean Mode #
 ######################################
  @shold = split(/T/,$sensorlist[$i]);

  if($shold[0] ne $sensorlist[$i])
  {
   $sennum = $shold[1] - 1;
   print OUTF "sent $sennum,1 \n";
   print OUTF "senm $sennum,1,0 \n";
   
   if($shold[1] == 1) { $sensor1 += 1;}
   if($shold[1] == 2) { $sensor2 += 1;}
   if($shold[1] == 3) { $sensor3 += 1;}
   
   next;
  }

 ###################################################
 # Light Sensor - Reflection PercentFullScale Mode #
 ###################################################
  @shold = split(/L/,$sensorlist[$i]);

  if($shold[0] ne $sensorlist[$i])
  {
   $sennum = $shold[1] - 1;
   $useLight = 1;
   print OUTF "sent $sennum,3 \n";
   print OUTF "senm $sennum,4,0 \n";
   
   if($shold[1] == 1) { $sensor1 += 1;}
   if($shold[1] == 2) { $sensor2 += 1;}
   if($shold[1] == 3) { $sensor3 += 1;}
  }
 }

 if($sensor1 > 1 || $sensor2 > 1 || $sensor3 > 1)
 {
  die "\nERROR : More than one sensor connected to same port.\n";
 }   

 #########################
 # Initialize Light Vars #
 #########################
 if($useLight == 1)
 {
  print OUTF "\n// -- Initial Values for LIGHT and DARK --\n";
  print OUTF "setv LIGHT,2,$light \n";
  print OUTF "setv DARK,2,$dark \n";
 }

}#end initSensors

##################################################################
## initVars() - initializes all user-defined variables with an  ##
##              LASM identifier. This allows the LASM code to   ##
##              access all variables by their label.            ##
##################################################################

sub initVars{
my($i);

 if ($varlist[0] ne undef){
  print OUTF "\n// -- Variable Definitions -- \n";
  }

 for ($i=0; $varlist[$i] ne undef; $i++)
 {
  print OUTF "#define  $varlist[$i]  $i \n";
 
  if($varlist[$i] eq "INTLOOPCLK")
  {
   die "ERROR: '$varlist[$i]' is a reserved word. Cannot be declared.\n";
  }
 }
 
 print OUTF "#define  INTLOOPCLK  $i \n";
 
} #end initVars 


##################################################################
## sensorValue(sensor,state) - will return the numeric value of ##
##                       the sensor in LASM format.             ##
##																##
##             sensor - sensor or variable to be tested         ##
##             state  - current decision state name             ## 
##################################################################

sub sensorValue{
my($senret);
my($ret);

 $senret = checkSensor($_[0]);

 if ($_[0] eq "T1" || $_[0] eq "L1") 
 {   
   if ($senret == 1) { return 0; }
   else { 
    die "ERROR: Sensor $_[0] was used but not initialized in $_[1]\n"; } 
 }
  
 if ($_[0] eq "T2" || $_[0] eq "L2") 
 { 
  if ($senret == 1) { return 1; }
   else { 
    die "ERROR: Sensor $_[0] was used but not initialized in $_[1]\n"; } 
 }

 if ($_[0] eq "T3" || $_[0] eq "L3") 
 { 
  if ($senret == 1) { return 2; }
   else { 
    die "ERROR: Sensor $_[0] was used but not initialized in $[1]\n"; } 
 }
 
 $ret = checkVar($_[0]); 
 if($ret == 0){
  die "ERROR : Invalid Decision Box Variable $_[0] in state $_[1] \n";
  }

 #argument is an expression so just return it
 return $_[0];
} #end sensorValue

#################################################################
## varDecBox(command,state) - Variable Decision Box. Handles   ##
##          all comparative operators inside of a decision box ##
##          Takes a command and state as its arguments.        ##
##             FORM : VAR1 [op] VAR2                           ##
#################################################################
sub varDecBox{
my($val1);
my($val2);
my($src1);
my($src2);
my($relop);
my($varset);
my($chkvar);
my($chksen);
my(@vhold);

$val1=0;
$val2=0;
$src1=0;
$src2=0;
$relop=0;
$varset=0;

  
  @vhold = split(/!=/,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 3; }
 
 if($varset == 0){
  @vhold = split(/=/,$_[0]);
  if($vhold[0] ne $_[0]) 
  { $varset = 1;
    $relop = 2; }}

  if($varset == 0){
    @vhold = split(/>/,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 0; }}

  if($varset == 0){
    @vhold = split(/</,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 1; }}

# check VAR1
  if($varset == 0){
   die "\nERROR: Illegal Operator in expression $_[0] in state $_[1]\n";
   }

   $chkvar = checkVar($vhold[0]);

   if ($chkvar == 0){
     $chksen = checkSensor($vhold[0]);
	 if ($chksen == 0)
	 {
	  error($vhold[0],1,$_[1]);
	  }
	}

# set up VAR1 arguments
   if($chkvar == 1)
   {
     if ($vhold[1]=~ /^[0-9]/)  #check for constant
	{ $src2=2;}
	else
	{
	 $src2 = 0;
	}
     
	 $val1 = $vhold[0];
	}
   else #VAR1 is a sensor
   {
     $src1 = 9;
     $val1 = sensorValue($vhold[0],$_[1]);
    }
   
   
#check VAR2   

   $chkvar = checkVar($vhold[1]);

   if ($chkvar == 0){
     $chksen = checkSensor($vhold[1]);
	 if ($chksen == 0)
	 {
	  error($vhold[1],1,$_[1]);
	  }
	}

	# set up VAR2 arguments
   if($chkvar == 1)
   {
    if ($vhold[1]=~ /^[0-9]/)  #check for constant
	{ $src2=2;}
	else
	{
	 $src2 = 0;
	}
	
	 $val2 = $vhold[1];
	}
   else #VAR2 is a sensor
   {
     $src2 = 9;
     $val2 = sensorValue($vhold[1],$_[1]);
    }

 # Print chkl command

 print OUTF "chkl $src1,$val1,$relop,$src2,$val2,$_[1]"."_1\n";
} #end varDecBox

######################################################################
## createMealyState() -        creates all Mealy output decision    ##
##                      checks and output asserts. It does this by  ##
##                      creating a series of labels to jump around  ##
##                      in the code.                                ##
##                                                                  ##
## Precondition : getMealyStates() is called before this function   ##
##                is called. It creates an array called @TMEALY     ##  
##                that contains all decision and Mealy boxes        ## 
##                branching from the current state box.             ##
##                @MEALYI contains the index of the item in its     ##
##                respective arrays.                                ##
##                                                                  ##
## @TMEALY = {statebox,dec1,0->Mealy,1->Mealy,dec2,...}             ##
## @TMEALYI= {   ,dec1 pos, mealy pos, mealy pos, dec2 pos,...}     ##
##  NOTE:  any branch that does not contain a Mealy box will        ##
##         contain a blank or $empty                                ##
######################################################################
sub createMealyState{
my($i);
my($j);
my($curstate);
my($decnum);
my($destnum);
my($maxdest);
my($mclock);
my($delay);
local(@mealyops);
local(@mealydec);


if($TMEALY[0] eq undef){
die "\nERROR: TMEALY array structure not created. \n";}


if($TMEALYI[1] eq undef){ 
  die "\nERROR: TMEALYI array structure not created. \n";}

print OUTF "//  -- Mealy Portion of $TMEALY[0] -- \n";

 #########################
 # Mealy Initializations #
 #########################
 
 $empty = "-"; #empty character in a mealy position
 
 # Create Mealy Decision Array for reference
 $j=0;
 for ($i=1; @TMEALY[$i]; $i+=3)
 {
  $mealydec[$j] = $TMEALY[$i];
  $j++;
 }
 $maxdest = $j;

###############################################################
# Set Loop Counter (number of loops in clock tick)            #
#  NOTE: Must compensate for delays from mult. decision boxes #
#        ** THIS MAY NEED TWEAKING **                         #
###############################################################
if($maxdest < 4)
{$delay = $maxdest+1;}
else
{$delay = $maxdest;}

if($clocktick >= 400)
 {$mclock = ($clocktick - (($delay)*100));}
if($clocktick >= 200 && $clocktick < 400)
 {$mclock = ($clocktick - (($delay)*50));}
if($clocktick >= 100 && $clocktick < 200)
 {$mclock = ($clocktick - (($delay)*25));}
if($clocktick < 100)
 {$mclock = ($clocktick - (($delay)*10));}

 if($mclock < 10)
 { 
  print OUTF "setv INTLOOPCLK,2,$clocktick \n";
 }
 else
 {
  print OUTF "setv INTLOOPCLK,2,$mclock \n";
 }

 ###################################
 # Main Mealy Output Code Creation #
 ###################################
 
 for($curstate=1; $TMEALY[$curstate] ne undef; $curstate +=3)
 {
  # use position is decision array for label
   $decnum = findMDecPos($TMEALY[$curstate]);
   
     print OUTF "$TMEALY[0]_$decnum: \n";

 
 # evaluate decision box (always use zero path)
  MvarDecBox($decision{@decisionnames[$TMEALYI[$curstate]]}{expression}
	        ,$TMEALY[0]);

 # 0-> path
  if($TMEALY[$curstate+1] ne $empty) {
 	print OUTF "$TMEALY[0]_M_$decnum";
	print OUTF "_0 \n"; }
   else
   { print OUTF "$TMEALY[0]_M_$decnum \n"; }

 # 1-> path
  if($TMEALY[$curstate+2] ne $empty){
   print OUTF "jmpl $TMEALY[0]_M_$decnum";
   print OUTF "_1 \n";}
  else
  {
    $destnum = findMDecPos(
	           $decision{@decisionnames[$TMEALYI[$curstate]]}{one});
    print OUTF "jmpl $TMEALY[0]_$destnum \n";
  }
 }
  # remaining loop decrement code

  print OUTF "$TMEALY[0]_$maxdest: \n";
  print OUTF "wait 2,1 \n";
  print OUTF "decvjnl INTLOOPCLK,$TMEALY[1] \n";
  print OUTF "jmpl $TMEALY[0]_0 \n\n";
#############################################################
  ###########################
  ## Mealy Operations Code ##
  ###########################			   

 for($curstate=1; $TMEALY[$curstate] ne undef; $curstate +=3)
 {
  # use position is decision array for label
   $decnum = findMDecPos($TMEALY[$curstate]);

 ############################
 # Mealy commands on 0 Path #
 ############################

   if($TMEALY[$curstate+1] ne $empty)
   {
    print OUTF "$TMEALY[0]_M_$decnum";
	print OUTF "_0: \n";

    for($i=0; $mealy{@mealynames[$TMEALYI[$curstate+1]]}{value}[$i] ne undef;
	    $i++)
	{
	  $mealyops[$i] = $mealy{@mealynames[$TMEALYI[$curstate+1]]}{value}[$i];
	 }

    mealyCommands(@mealyops);

    $destnum = findMDecPos(
	           $mealy{@mealynames[$TMEALYI[$curstate+1]]}{destination});

    print OUTF "jmpl $TMEALY[0]_$destnum \n";	
   }

 ##############################
 # non-Mealy path on 0 branch #
 ##############################

   if($TMEALY[$curstate+1] eq $empty )
   {
    print OUTF "$TMEALY[0]_M_$decnum: \n";

    $destnum = findMDecPos(
	           $decision{@decisionnames[$TMEALYI[$curstate]]}{zero});
	
	print OUTF "jmpl $TMEALY[0]_$destnum \n\n";
    }


 ###########################
 # Mealy command on 1 Path #
 ###########################

   if($TMEALY[$curstate+2] ne $empty)
   {
    print OUTF "$TMEALY[0]_M_$decnum";
	print OUTF "_1: \n";

    for($i=0; $mealy{@mealynames[$TMEALYI[$curstate+1]]}{value}[$i] ne undef;
	    $i++)
	{
	  $mealyops[$i] = $mealy{@mealynames[$TMEALYI[$curstate+2]]}{value}[$i];
	 }

    mealyCommands(@mealyops);

    $destnum = findMDecPos(
	           $mealy{@mealynames[$TMEALYI[$curstate+2]]}{destination});

    print OUTF "jmpl $TMEALY[0]_$destnum \n\n";	
   }
 
  } 

  print OUTF "// -- End Mealy Box $TMEALY[0] -- \n\n";
} #end createMealyState()

#########################################################
## findMDecPos(DecName) - looks in @mealydec array and ##
##                        returns its position         ##
#########################################################
sub findMDecPos{
my($i);

 for($i=0; $mealydec[$i] ne undef; $i++)
 {
   if($mealydec[$i] eq $_[0])
   { return $i;}
 }

 return $i;
}
    
#################################################################
## MvarDecBox(command,state) -      creates Mealy Decision Ops ##
##                                                             ##
##             FORM : VAR1 [op] VAR2                           ##
##  NOTE : Does NOT write destination. That is handled in the  ##
##         calling function                                    ##
#################################################################
sub MvarDecBox{

my($val1);
my($val2);
my($src1);
my($src2);
my($sens);
my($relop);
my($varset);
my($chkvar);
my($chksen);
my(@vhold);

$val1=0;
$val2=0;
$src1=0;
$src2=0;
$relop=0;
$varset=0;

# check for single sensor

  $chksen = checkSensor($_[0]);
               
 if($chksen == 1)
 {
   $sens = sensorValue($_[0],$_[1]);
   
  if($_[0] eq "L1" || $_[0] eq "L2" || $_[0] eq "L3")
  {
   print OUTF "chkl 0,LIGHT,0,9,$sens,";
  }
  else
  {
   print OUTF "chkl 2,1,2,9,$sens,"; 
  }
   return;
 }
   
# whole expression found
   
    @vhold = split(/!=/,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 3; 
	}
 
 if($varset == 0){
  @vhold = split(/=/,$_[0]);
  if($vhold[0] ne $_[0]) 
  { $varset = 1;
    $relop = 2;
  }
 }

  if($varset == 0){
    @vhold = split(/>/,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 0;
	}
   }

  if($varset == 0){
    @vhold = split(/</,$_[0]);
    if($vhold[0] ne $_[0]) 
    { $varset =1;
      $relop = 1; 
	}
   }

# check VAR1
  if($varset == 0){
   die "\nERROR: Illegal Operator in expression $_[0] in state $_[1]\n";
   }

   $chkvar = checkVar($vhold[0]);

   if ($chkvar == 0){
     $chksen = checkSensor($vhold[0]);
	 if ($chksen == 0)
	 {
	  error($vhold[0],1,$_[1]);
	  }
	}

# set up VAR1 arguments
   if($chkvar == 1)
   {
     if ($vhold[1]=~ /^[0-9]/)  #check for constant
	{ $src2=2;}
	else
	{
	 $src2 = 0;
	}
     
	 $val1 = $vhold[0];
	}
   else #VAR1 is a sensor
   {
     $src1 = 9;
     $val1 = sensorValue($vhold[0],$_[1]);
    }
   
   
#check VAR2   

   $chkvar = checkVar($vhold[1]);

   if ($chkvar == 0){
     $chksen = checkSensor($vhold[1]);
	 if ($chksen == 0)
	 {
	  error($vhold[1],1,$_[1]);
	  }
	}

	# set up VAR2 arguments
   if($chkvar == 1)
   {
    if ($vhold[1]=~ /^[0-9]/)  #check for constant
	{ $src2=2;}
	else
	{
	 $src2 = 0;
	}
	
	 $val2 = $vhold[1];
   }
   else #VAR2 is a sensor
   {
     $src2 = 9;
     $val2 = sensorValue($vhold[1],$_[1]);
    }

 # Print chkl command

 print OUTF "chkl $src1,$val1,$relop,$src2,$val2,";
} #end MvarDecBox


################################################################
## mealyCommands(@commands) - outputs all commands from mealy ##
##                            box. Takes array of commands as ##
##                            an argument.                    ##
################################################################

sub mealyCommands{
my($j);
my($execOp);
my(@hold);

 for($j=0; $_[$j] ne undef; $j++)
 {

  # This code will first split the command by motor letter A B and C
  # If the letter is found, it will look at the remainder of the split to do
  # compilation.
  
  $execOp = 0; # flag to see if operation executed (compiled)

  ###########
  # Motor A #
  ###########
   @hold = split(/A/,$_[$j]); #check all things with A

   if ($hold[0] ne $_[$j])
   {
    if ($hold[1] eq "on")    {$execOp = 1;
	                          print OUTF "out 2,1\n";}
    if ($hold[1] eq "off")   {$execOp = 1;
	                          print OUTF "out 1,1\n";}
    if ($hold[1] eq "float") {$execOp = 1;
	                          print OUTF "out 0,1\n";}
    if ($hold[1] eq "f")     {$execOp = 1;
	                          print OUTF "out 2,1\n";
	                          print OUTF "dir 2,1\n";}
    if ($hold[1] eq "b")     {$execOp = 1;
	                          print OUTF "out 2,1\n";
	                          print OUTF "dir 0,1\n";}
	if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")  
	                        {$execOp = 1;
							 print OUTF "pwr 1,2,$hold[1] \n";}
   }
  

  ###########
  # Motor B #
  ###########
  if($execOp == 0)
  { 
   @hold = split(/B/,$_[$j]); #check all things with B

   if ($hold[0] ne $_[$j])
   {
    if($hold[1] eq 'on')    {$execOp = 1;
	                         print OUTF "out 2,2\n";}
    if($hold[1] eq 'off')   {$execOp = 1;
	                         print OUTF "out 1,2\n";}
    if($hold[1] eq 'float') {$execOp = 1;
	                         print OUTF "out 0,2\n";}
    if($hold[1] eq 'f')     {$execOp = 1;
	                         print OUTF "out 2,2\n";
	                         print OUTF "dir 2,2\n";}
    if($hold[1] eq 'b')     {$execOp = 1;
	                         print OUTF "out 2,2\n";
	                         print OUTF "dir 0,2\n";}
	if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")  
	                        {$execOp = 1;
							 print OUTF "pwr 2,2,$hold[1] \n";}
   }
  }

  ###########
  # Motor C #
  ###########
  if($execOp == 0)
  { 
   @hold = split(/C/,$_[$j]); #check all things with C 

   if ($hold[0] ne $_[$j])
   {
    if($hold[1] eq 'on')    {$execOp = 1;
	                         print OUTF "out 2,4\n";}
    if($hold[1] eq 'off')   {$execOp = 1;
	                         print OUTF "out 1,4\n";}
    if($hold[1] eq 'float') {$execOp = 1;
	                         print OUTF "out 0,4\n";}
    if($hold[1] eq 'f')     {$execOp = 1;
	                         print OUTF "out 2,4\n";
	                         print OUTF "dir 2,4\n";}
    if($hold[1] eq 'b')     {$execOp = 1;
	                         print OUTF "out 2,4\n";
	                         print OUTF "dir 0,4\n";}
	if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || $hold[1] eq "3" ||
	   $hold[1] eq "4" || $hold[1] eq "5" || $hold[1] eq "6" || $hold[1] eq "7")  
	                        {$execOp = 1; 
							 print OUTF "pwr 4,2,$hold[1] \n";}
   }
  }

  #####################################################
  # Assignment  FORM : VAR <- VAR [operator] CONSTANT #
  ##################################################### 
  if($execOp == 0)
  { 
   @hold = split(/<-/,$_[$j]); #check for variable assignment
   
   if ($hold[0] ne $_[$j])
   {  
    $execOp = 1;
    assign($hold[0],$hold[1]," ");
   }
  }

  ##########
  # Sounds #
  ##########
  if($execOp == 0)
  {
   @hold = split(/sound/,$_[j]); #check all things with sound

   if ($hold[0] ne $state{@statenames[$i]}{value}[$j])
   {
    if($hold[1] eq "0" || $hold[1] eq "1" || $hold[1] eq "2" || 
	   $hold[1] eq "3" || $hold[1] eq "4" || $hold[1] eq "5")  
	{
     $execOp = 1;
	 print OUTF "plays $hold[1] \n";
    }
   }
  }

  if($execOp == 0)
  { die "Unrecognized Mealy Command: $_[j] \n"; }

 }
} 
# end mealyCommands
