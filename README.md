# FPC-CCMPC

CCMPC graph plotting tool
Graph plotter browse and opens logs obtained through CCMPC software. Logs are text files (".TXT") containing data in comuns, where each column represent diesel engine 
parameter(do not mix with software "engine"), parameters like engine speed, exhaust gas temperature, boost pressure etc.

For graph plotter to work correctly, log files must be located in dedicated folder:
C:\CCMPC\CCMEXE\DATALOG\ ..

alternatively, user can modify function "ChooseFile"  in a  "DisplayAndChoose" unit. This is well documented within the code. The line ChDir('C:\CCMPC...') 
needs to be modified to suit your needs.

Graph plotter is built for my specific needs, and therefore its functionality is limited to text files having a certain arrangement:

1. All entries within the log files are separated by comma ',' without spaces before or after.
2. Each array (vector) is a column.
3. First three lines in text file contain non-numeric data as follow:
 a) first line is date and time stamp, unit ID (engine's serial number) and log particulars
 b) second line is measuring unit for each parameter ( bars, kPa, RPM, etc)
 c) third line contains the name of parameter (Boost Pressure, Oil Temperature... etc)
 d) bulk of data is beginning at line 4
 e) last line is also non-numeric, containing time signature and other not critical info
 
graph plotter is built entirely on Pascal's Graph unit. I tried to adhere to vanila Pascal variety with minimal use extentions.

Once file is choosen, you will be provided with list of available paramters for plotting. Pick channel of interest by left click of the mouse.

De-select, if needed, by right click of a mouse.

Columns "as is" and "least sq" are not utilized. Those are remnants of wishful thinking.
Moving average will smooth out some dirty data. Notorious for being dirty are engine cranckcase pressure, boost pressure, exhaust gas temperatures, 
turbo inlet pressure.

Some channels contain very stable parameters, values are not changing. Those will be plotted as horizontal lines, sometimes too close to upper border and not visible.

Graph controls:

			    [W] - zoom in
	[A]  - pan left		[D]  -pan right
			    [S] - zoom out

Change colors - [C]

Save Graph      - [R]

Exit		[ENTER]

click anywhere within graph area will cause the graph to be re-plotted with vertical white dashed line at the mouse pointer. Values for every parameter on the 
graph will be displayed, along with time signature on the right bottom of the graph.

If you want to explore certain area of graph in more detail, drad mouse pointer with left button pressed across the area. Graph will zoom in to area between click and release.
Pressing right mouse button will take you back to original size of graph.

Graph save functionality is very rudimental. It relies on FPC generating random number, which is added to generic name 'Graph', Graph54, Graph31 ... etc. 
Image is saved in bitmap format in same directory where logs are. Please rename images immediately after, or they will be re-written at next run of the application.
I provided a few example logs for different engines. Any file with .txt extension (except this one ) is engine log.

Have Fun!
