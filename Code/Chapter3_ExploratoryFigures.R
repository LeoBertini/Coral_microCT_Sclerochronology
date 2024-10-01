library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lme4)
library(lmerTest)
library(reshape2)
library(ggrepel)
library(randomcoloR)
library(ggnewscale)
library(cowplot)
library(RColorBrewer)
library(svglite)

#FUNCTIONS
MGA_PipePlot = function(Dataframe, variable, xmin, xmax, ymin, ymax, xbreak, ybreak){
  
  if(missing(xbreak)) {
    xbreak=10
  }
  
  if (variable =='Ext_cmyr'){
  variable_name = 'Track Extension Rate'
  ylabel_mod =bquote(atop('Track Extension Rate'))
  }
  
  if (variable =='Ext_mmyr'){
    variable_name = 'Track Extension Rate'
    ylabel_mod =bquote(atop('Track Extension Rate'))
  }
  
  if (variable =='TrackDensity'){
    variable_name = 'Track Density'
    ylabel_mod = bquote(atop('Track Density'))
  }
  
  if (variable =='TrackCalcification'){
    variable_name = 'Track Calcification Rate'
    ylabel_mod = bquote(atop('Track Calcification Rate'))
  }
  
  if (variable =='AMR_Ext_avg'){
    variable_name = 'AMR Extension Rate'
    ylabel_mod = bquote(atop('AMR Extension Rate'))
  }
  
  PLOT =     ggplot(aes(x=year, y=.data[[variable]], 
             group = CoralColony,
             color = Location,
             shape = DatingConfident),
             data = Dataframe) +
    
    scale_color_manual(values = color_scheme)+
    scale_shape_manual(values=c(4, 21))+
    
    
    scale_x_continuous(limits=c(xmin,xmax), breaks=seq(1800,xmax,xbreak))+
    scale_y_continuous(limits=c(ymin,ymax), breaks=seq(ymin,ymax, ybreak), labels = function(x) format(x, nsmall = 2))+
    
    geom_point(size=2, alpha=.5)+
    geom_line(linewidth=.5, linetype='solid')+
    
    theme_bw() + 
    theme(axis.text = element_text(size = 12, color = 'black'), 
          axis.title = element_text(size = 12), 
          panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
          panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
          legend.position = "none")+
    
    ylab(ylabel_mod)+
    xlab('Year')
         
    return (PLOT)     
  
}

# Getting the path of current R file.. this is where figures will be saved by default
setwd('/Users/leonardobertini/Library/CloudStorage/OneDrive-SharedLibraries-UniversityofBristol/grp-Chapter 4 - Leo - General/RScripts')
   
# importing datasets
datapath ="/Users/leonardobertini/Library/CloudStorage/OneDrive-SharedLibraries-UniversityofBristol/grp-Chapter 4 - Leo - General/Results/Coral_Growth_Data_Chapter4.xlsx"
MGA_DF = read_excel(datapath, sheet = 'DataArrangedForPlot')
MGA_DF$Ext_cmyr = MGA_DF$Ext_mmyr*0.1

AMR_DF = read_excel(datapath, sheet = 'CalciRates')

Complete_DF = merge(MGA_DF,AMR_DF, by='CoralColony')
Complete_DF = within(Complete_DF, rm('ExtType_MinOrMax'))
Complete_DF = distinct(Complete_DF)
Complete_DF$TotalAgeMax = as.numeric(Complete_DF$TotalAgeMax)
Complete_DF$TotalAgeMax = as.numeric(Complete_DF$TotalAgeMin)
Complete_DF$AMR_Ext_min = Complete_DF$AMR_MeanDistance_cm*10 / Complete_DF$TotalAgeMax
Complete_DF$AMR_Ext_max = Complete_DF$AMR_MeanDistance_cm*10 / Complete_DF$TotalAgeMin
Complete_DF$AMR_Ext_avg = (Complete_DF$AMR_Ext_min + Complete_DF$AMR_Ext_max)/2
Complete_DF$Calci_AMR_avg = (Complete_DF$Calci_AMR_max + Complete_DF$Calci_AMR_min)/2


# Averaging MGA Track data for GIS maps and other Plots -------------------------------------------------------------------------
DF_GIS = MGA_DF %>%
  group_by(CoralColony) %>%
  summarize(MeanExt = mean(Ext_mmyr, na.rm=TRUE),
            MeanDensity = mean(TrackDensity, na.rm=TRUE),
            MeanCalcification = mean(TrackCalcification, na.rm=TRUE))


DF_GIS_merged = merge(DF_GIS, MGA_DF, by="CoralColony")
DF_GIS_merged = DF_GIS_merged[c("CoralColony",
                                "Location",
                                "MeanExt",
                                "MeanDensity",
                                "MeanCalcification",
                                "Collected_in")]
                              
DF_GIS_merged = distinct(DF_GIS_merged)
write.csv(DF_GIS_merged, "MGA_averaged_values.csv")

#MERGING AMR dataset with MGA Dataset ---------------------------------
Complete_DF = merge(Complete_DF,DF_GIS_merged, by='CoralColony')
Complete_DF = within(Complete_DF, rm("Ext_mmyr", "Ext_cmyr","TrackLength","TrackDensity","TrackCalcification", "Track_index",
                           "TrackDurationMin","TrackDurationMax" ,"YearRangeMin","YearRangeMax", "Location.y", "Collected_in","Collected_in.y", "Location"))
Complete_DF = distinct(Complete_DF)

Complete_DF  = Complete_DF %>%
  rename(
    Collected_in = Collected_in.x,
    Location = Location.x,
    MGA_MeanExt = MeanExt,
    MGA_MeanDensity = MeanDensity,
    MGA_MeanCalcification = MeanCalcification
  )

# get colorpallete based on Locations ------------------------------------
colourcount =length(unique(Complete_DF$Location))
getPallete = colorRampPalette(brewer.pal(8,"Set1"))

color_scheme=c( '#e6194B', '#bd7dbd', '#4363d8','#0000ffff',
                '#f58231', '#911eb4', '#42d4f4','#006400',
                '#32CD32ff', '#c5e513ff', '#469990','#ff00ccfa',
                '#000000', '#5A5A5A', '#C78752','#808000',
                '#800020', '#11afccff', '#FFC000', '#f4cccc','#42d4f4', '#469990', 'red','blue', 'green', '#c294cf','#c21c45' ,
                '#f58231', '#911eb4','#A3AABE','#32CD32ff', '#11afccff', '#ff00ccfa', 
                '#5A5A5A', '#c0ccc0','#808000', '#c97f7f', '#c5e513ff','#179FE0','#a2d8f2','#AFCCFF',
                '#FFC000','#817567','#6c8dc5', '#f785c9',
                '#a97947','#81b781','#ffe599', '#97ebdb','#CC0066', '#69BFA2','#0066CC', '#CCFFCC')



# DOING INITIAL PLOTS
Complete_DF_V = Complete_DF[Complete_DF$Slab_Orientation=='Vertical',]
Complete_DF_H = Complete_DF[Complete_DF$Slab_Orientation=='Horizontal',]

#TODO 
# AMR Vertical vs Horizontal EXT -------------------------------------------------------------------------
#doing change from long to wide data
Complete_DF_VandH = merge(Complete_DF_H,Complete_DF_V, by = "CoralColony")

AMR_Hor_and_V = ggplot(aes(
                      x=AMR_Ext_avg.x ,
                      y=AMR_Ext_avg.y,
                      fill=Location.x,
                      color=Location.x),
                      data = Complete_DF_VandH) +
  scale_x_continuous(limits=c(4,20), breaks=seq(0,20,2))+
  scale_y_continuous(limits=c(4,20),breaks=seq(0,20,2))+
  geom_point(shape = 21, stroke=2)+
  geom_abline(intercept = 0)+
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'),
        axis.title = element_text(size = 12),
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        legend.position = "none")+
  ylab(bquote(atop('AMR-V extension (mm'~y^-1~')')))+
  xlab(bquote(atop('AMR-H extension (mm'~y^-1~')')))+
  ggtitle('AMR: Horizontal vs Vertical extension')

AMR_Hor_and_V_labelled = AMR_Hor_and_V+
                               geom_label_repel(aes(label = CoralColony, fill=NULL),
                               box.padding   = 0.50, 
                               point.padding = 0.5,
                               segment.color = 'grey50',
                               max.overlaps = 20,
                               size = 2) 


# AMR data (EXT x DENSITY) -------------------------------------------------------------------------
AMR_VExt_Density =ggplot(aes(
                      x=AMR_Ext_avg.y ,
                      y=AMR_MeanDensity_gcm3.y,
                      fill=Location.x,
                      color=Location.x),
                      data = Complete_DF_VandH) +
  geom_smooth(inherit.aes = FALSE,
              aes(x=AMR_Ext_avg.y ,
                  y=AMR_MeanDensity_gcm3.y),
              method="lm",
              se=TRUE, fullrange=FALSE, level=0.95,
              color='black', linetype = 'dashed') +
  geom_point(shape = 21, stroke=2)+
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(4,20), breaks=seq(0,20,2))+
  scale_y_continuous(limits=c(1, 1.8),breaks=seq(1, 1.8,.2))+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'),
        axis.title = element_text(size = 12),
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        legend.position = "none")+
  ylab(bquote(atop('AMR-V Density (g '~cm^-3~')')))+
  xlab(bquote(atop('AMR-V Extension (mm'~y^-1~')')))+
  ggtitle('AMR: Vertical Extension vs Density')


AMR_VExt_Density_labelled = AMR_VExt_Density+geom_label_repel(aes(label = CoralColony, fill=NULL),
                 box.padding   = 0.50, 
                 point.padding = 0.5,
                 segment.color = 'grey50',
                 max.overlaps = 20,
                 size = 2) 


# AMR extension vs MGA Extension -------------------------------------------------------------------------
AMR_VExt_MGA_Extension = ggplot(aes(
                      x=AMR_Ext_avg.y ,
                      y=MGA_MeanExt.y,
                      fill=Location.x,
                      color=Location.x),
                      data = Complete_DF_VandH) +
  geom_point(shape = 21, stroke=2)+
  geom_abline(intercept = 0)+
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(4,20), breaks=seq(0,20,2))+
  scale_y_continuous(limits=c(4,20), breaks=seq(0,20,2))+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'),
        axis.title = element_text(size = 12),
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        legend.position = "none")+
  ylab(bquote(atop('MGA Extension (mm'~y^-1~')')))+
  xlab(bquote(atop('AMR-V Extension (mm'~y^-1~')')))+
  ggtitle('AMR vs MGA: Extension')

AMR_VExt_MGA_Extension_labelled = AMR_VExt_MGA_Extension+ geom_label_repel(aes(label = CoralColony, fill=NULL),
                                                                           box.padding   = 0.50,
                                                                           point.padding = 0.5,
                                                                           segment.color = 'grey50',
                                                                           max.overlaps = 20,
                                                                           size = 2)


# AMR density vs MGA Density -------------------------------------------------------------------------
AMR_Density_MGA_Denstity = ggplot(aes(x=AMR_MeanDensity_gcm3.y ,
                                      y=MGA_MeanDensity.y,
                                      fill=Location.x,
                                      color=Location.x),
                                  data = Complete_DF_VandH) +
  geom_abline(intercept = 0)+
  geom_smooth(inherit.aes = FALSE,
              aes(x=AMR_MeanDensity_gcm3.y ,
                  y=MGA_MeanDensity.y),
              method="lm",
              se=TRUE, fullrange=FALSE, level=0.95,
              color='black', linetype = 'dashed') +
  geom_point(shape = 21, stroke=2)+
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(1, 1.8),breaks=seq(1, 1.8,.2))+
  scale_y_continuous(limits=c(1, 1.8),breaks=seq(1, 1.8,.2))+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'),
        axis.title = element_text(size = 12),
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        legend.position = "none")+
  ylab(bquote(atop('MGA Density (g'~cm^-3~')')))+
  xlab(bquote(atop('AMR-V Density (g'~cm^-3~')')))+
  ggtitle('AMR vs MGA: Density')

AMR_Density_MGA_Denstity_labelled = AMR_Density_MGA_Denstity+geom_label_repel(aes(label = CoralColony, fill=NULL),
                                                                               box.padding   = 0.50,
                                                                               point.padding = 0.5,
                                                                               segment.color = 'grey50',
                                                                               max.overlaps = 20,
                                                                               size = 2)


# MGA Averaged EXT and Density-------------------------------------------------------------------------
MGA_Extension_MGA_Density =  ggplot(aes(x=MeanExt, y=MeanDensity,
                                        group = CoralColony,
                                        color = Location,
                                        fill=Location),
                                    data = DF_GIS_merged)+
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(4,20), breaks=seq(0,20,2))+
  scale_y_continuous(limits=c(1, 1.8),breaks=seq(1, 1.8,.2))+
  geom_smooth(inherit.aes = FALSE, aes(x=MeanExt, y=MeanDensity),
              method="lm",
              se=TRUE, fullrange=FALSE, level=0.95,
              color='black', linetype = 'dashed') +
  geom_point(shape = 21, stroke=2)+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'), 
        axis.title = element_text(size = 12), 
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
        legend.position = "none")+
  ylab(bquote(atop('MGA Density (g'~cm^-3~')')))+
  xlab(bquote(atop('MGA Extension (mm'~y^-1~')')))+
  ggtitle('MGA: Extension vs Density')

MGA_Extension_MGA_Density_labelled = MGA_Extension_MGA_Density + geom_label_repel(aes(label = CoralColony, fill=NULL),
                                                                                    box.padding   = 0.50,
                                                                                    point.padding = 0.5,
                                                                                    segment.color = 'grey50',
                                                                                    max.overlaps = 20,
                                                                                    size = 2)

# 
# ggsave(filename="MGAAveragedData.svg",
#        plot = MGA_Extension_MGA_Density,
#        device = svglite, 
#        width = 10,
#        height = 15,
#        units = "cm")



aaaaaaa=plot_grid(AMR_Hor_and_V_labelled,
          AMR_VExt_MGA_Extension_labelled,
          AMR_Density_MGA_Denstity_labelled,
          NULL,
          MGA_Extension_MGA_Density_labelled,
          AMR_VExt_Density, nrow=3, ncol= 2)

# MGA TEMPORAL DATA -- DOING SOME TABLE MANIPULATION SO DATA CAN BE PLOTED

DF_MinExt = MGA_DF %>% filter(grepl('Min', ExtType_MinOrMax))
DF_MaxExt = MGA_DF %>% filter(grepl('Max', ExtType_MinOrMax))

DF_MinExt_2 = DF_MinExt %>%
  dplyr::rowwise() %>%
  dplyr::mutate(year = list(seq(YearRangeMin, YearRangeMax))) %>%
  dplyr::select(-YearRangeMin, -YearRangeMax) %>%
  tidyr::unnest(c(year))

DF_MaxExt_2 =  DF_MaxExt %>%
  dplyr::rowwise() %>%
  dplyr::mutate(year = list(seq(YearRangeMin, YearRangeMax))) %>%
  dplyr::select(-YearRangeMin, -YearRangeMax) %>%
  tidyr::unnest(c(year))


##LOUGH TEMPORAL PIPE-PLOTS
# MGA Temporal PIPE PLOT ---------------------------------------------------------------
#Extension
FIG1 =  MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'Ext_mmyr', xmin=1805, xmax=1990, ymin=0, ymax=25, ybreak=5)
#Density
FIG2 =  MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'TrackDensity', xmin=1805, xmax=1990, ymin=0.75, ymax=2, ybreak=.25)
#Calcification 
FIG3 =  MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'TrackCalcification', xmin=1805, xmax=1990, ymin=0, ymax=3, ybreak=.5)

# MGA Temporal PIPE PLOT GRID and Save -----------------------------------------------------------------
MGA_PipePlot_Grid = plot_grid(FIG1, FIG2, FIG3, nrow=3, ncol= 1, labels = c('a)', 'b)', 'c)'))
MGA_PipePlot_Grid

legend_a <- get_legend(FIG3 + theme(legend.position="bottom"))


ggsave(filename="MGA_TrackData_NewColours.svg",
       plot = MGA_PipePlot_Grid,
       device = svglite::svglite,
       width = 297,
       height = 210,
       units = "mm")

ggsave(filename="Legend_NewColour.svg",
       device = svglite,
       dpi = 300,
       plot = legend_a,
       width = 297,
       height = 210,
       units = "mm")




# AMR Temporal ------------------------------------------------------------

Complete_DF = Complete_DF[!is.na(Complete_DF$YearRangeMin.x),]

Complete_DF_Expanded = Complete_DF %>%
  dplyr::rowwise() %>%
  dplyr::mutate(year = list(seq(YearRangeMin.x, YearRangeMax.x))) %>%
  dplyr::select(-YearRangeMin.x, -YearRangeMax.x) %>%
  tidyr::unnest(c(year))

require(forcats)
fct_relevel(Complete_DF_Expanded$Slab_Orientation , "Horizontal", "Vertical")

#function to plot AMR datasets
AMR_TemporalPLot = function(Dataframe, variable, xmin, xmax, ymin, ymax, xbreak, ybreak){
    
    if(missing(xbreak)) {
      xbreak=10
    }
    
    if (variable =='AMR_Ext_avg'){
      variable_name = 'AMR Extension Rate'
      ylabel_mod = bquote(atop('AMR Extension Rate'))
    }
  
  if (variable =='Ext_rate'){
    variable_name = 'Extension Rate'
    ylabel_mod = bquote(atop('Extension Rate'))
  }
  
  
  if (variable =='AMR_MeanDensity_gcm3'){
    variable_name = 'AMR Density Rate'
    ylabel_mod = bquote(atop('AMR Density'))
  }
  
  if (variable =='Calci_AMR_avg'){
    variable_name = 'AMR Calcification Rate'
    ylabel_mod = bquote(atop('AMR Calcification'))
  }
  

    PLOT =ggplot(aes(x=year, y=.data[[variable]], 
                          group = interaction(CoralColony,Slab_Orientation),
                          color = Location,
                          alpha = Slab_Orientation),
                      data = Dataframe) +
      
      geom_point(size=0.5)+
      
      scale_color_manual(values = color_scheme)+
      geom_line(aes(linetype=Slab_Orientation, alpha=Slab_Orientation),
                linewidth=1)+
      scale_linetype_manual(values=c('dotted','solid'))+
      scale_alpha_manual(values=c(0.5,1))+
      
      scale_x_continuous(limits=c(xmin,xmax), breaks=seq(1800,xmax,xbreak))+
      scale_y_continuous(limits=c(ymin,ymax), breaks=seq(ymin,ymax, ybreak), labels = function(x) format(x, nsmall = 2))+
     
      theme_bw() + 
      theme(axis.text = element_text(size = 12, color = 'black'), 
            axis.title = element_text(size = 12), 
            panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
            panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
            legend.position = "none")+
      
      ylab(ylabel_mod)+
      xlab('Year')
    
    return (PLOT)     
    
  }

FIG_AMR_Temp_EXT =  AMR_TemporalPLot(Dataframe = Complete_DF_Expanded, variable = 'AMR_Ext_avg', xmin=1805, xmax=1990, ymin=0, ymax=25, ybreak=5)

FIG_AMR_Temp_Density =  AMR_TemporalPLot(Dataframe = Complete_DF_Expanded, variable = 'AMR_MeanDensity_gcm3', xmin=1805, xmax=1990, ymin=.75, ymax=2, ybreak=.25)

FIG_AMR_Calci = AMR_TemporalPLot(Dataframe = Complete_DF_Expanded, variable = 'Calci_AMR_avg', xmin=1805, xmax=1990, ymin=0, ymax=3, ybreak=.5)

legend_b <- get_legend(FIG_AMR_Calci + theme(legend.position="bottom"))

AMR_TemporalFIG = plot_grid(FIG_AMR_Temp_EXT, FIG_AMR_Temp_Density, FIG_AMR_Calci, ncol= 1, labels = c('a)', 'b)', 'c)'))

# getting legend and saving to separate file -----------------------------------------------------------------

ggsave(filename="AMR_Timeline_NewColours.svg",
       plot = AMR_TemporalFIG,
       device = svglite::svglite,
       width = 297,
       height = 210,
       units = "mm")

legend_b <- get_legend(FIG_AMR_Calci + theme(legend.position="bottom"))

ggsave(filename="AMR_Legend_NewColours.svg",
       plot = legend_b,
       device = svglite::svglite,
       width = 297,
       height = 210,
       units = "mm")

# Zoomed 1910-1930s -----------------------------------------------------------------
FIG1_zoom = MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'Ext_cmyr', xmin=1910, xmax=1930, ymin=0.4, ymax=2.4, xbreak = 5, ybreak=.4)+
            geom_point(size=.5, alpha=1, stroke=1)+
            geom_line(linewidth=1.5, linetype='solid', alpha=.3)
FIG1_zoom


FIG2_zoom=MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'TrackDensity', xmin=1910, xmax=1930, ymin=1, ymax=1.8, xbreak = 5, ybreak=.2)+
  geom_point(size=.5, alpha=1, stroke=1)+
  geom_line(linewidth=1.5, linetype='solid', alpha=.3)
FIG2_zoom


FIG3_zoom=MGA_PipePlot(Dataframe = DF_MaxExt_2, variable = 'TrackCalcification', xmin=1910, xmax=1930, ymin=.8, ymax=2.8, xbreak = 5, ybreak=.2)+
  geom_point(size=.5, alpha=1, stroke=1)+
  geom_line(linewidth=1.5, linetype='solid', alpha=.3)
  
MGA_PipePlot_Zoomed=plot_grid(FIG1_zoom, FIG2_zoom, FIG3_zoom, nrow=3, ncol= 1, labels = c('a)', 'b)', 'c)'))

MGA_PipePlot_Zoomed


# AMR Extension Rate vs AMR Density with midpoints -----------------------------------------------------------------
# importing dataset
datapath="/Users/leonardobertini/Library/CloudStorage/OneDrive-SharedLibraries-UniversityofBristol/grp-Chapter 4 - Leo - General/Results/Coral_Growth_Data_Chapter4.xlsx" 
DF2 = read_excel(datapath, sheet = 'CalciRates')
DF2$midpoint = ((DF2$AMR_MeanDistance_cm*10)/DF2$TotalAgeMin + (DF2$AMR_MeanDistance_cm*10)/DF2$TotalAgeMax)/2
DF2 = DF2[DF2$Slab_Orientation=='Vertical',]


FIG5 =  ggplot(aes(x=midpoint, y=AMR_MeanDensity_gcm3, 
                   group=CoralColony,
                   color = Location,
                   fill=Location),
                   data = DF2)+
  
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  
  scale_x_continuous(limits=c(3,23), breaks=seq(3,23,1))+
  scale_y_continuous(limits=c(1, 1.9),breaks=seq(1, 1.9,.2))+
  
  geom_point(shape = 22, stroke=2)+
  geom_errorbarh(
    aes(xmax =(AMR_MeanDistance_cm*10)/TotalAgeMin , xmin = (AMR_MeanDistance_cm*10)/TotalAgeMax),
    linetype='dashed', alpha=0.4)+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'), 
        axis.title = element_text(size = 12), 
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
        legend.position = "none")+
  
  ylab(bquote(atop('AMR Density (g'~cm^-3~')')))+
  xlab(bquote(atop('AMR-V Extension (mm'~y^-1~')')))
 
FIG5

# getting legend -----------------------------------------------------------------
# FIG5_lgd = FIG5  +  theme(legend.position = "right")
# legend = get_legend(FIG5_lgd)
# grid.newpage()
# grid.draw(legend)
# ggsave(filename="Legend_Squares.svg", 
#        device = svglite, 
#        dpi = 300,
#        plot = legend,
#        width = 297, 
#        height = 210, 
#        units = "mm")


# AMR Extension Rate vs Bulk Density with midpoints -----------------------------------------------------------------
FIG6 =  ggplot(aes(x=midpoint, y=ColonyWeight/ColonyVolume, 
                   group=CoralColony,
                   color = Location,
                   fill=Location),
                   data = DF2)+
  
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  
  scale_x_continuous(limits=c(3,23), breaks=seq(3,23,1))+
  scale_y_continuous(limits=c(1, 1.9),breaks=seq(1, 1.9,.2))+
  
  geom_point(shape = 22, stroke=2)+
  geom_errorbarh(
    aes(xmax =(AMR_MeanDistance_cm*10)/TotalAgeMin , xmin = (AMR_MeanDistance_cm*10)/TotalAgeMax),
    linetype='dashed', alpha=0.4)+
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'), 
        axis.title = element_text(size = 12), 
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
        legend.position = "none")+
  
  ylab(bquote(atop('Bulk Colony Density (g'~cm^-3~')')))+
  xlab(bquote(atop('AMR Extension (mm'~y^-1~')')))

FIG6


# MGA Track Extension Rate vs MGA Track Density midpoints -----------------------------------------------------------------
#TODO for each Min-Max Extension rate pair, add mid-point for plot
coral_names = unique(MGA_DF$CoralColony)
coral_names = coral_names[1:49]
DF_midpoints  = MGA_DF

for (i in coral_names){
  temp_df = MGA_DF[MGA_DF$CoralColony==i,]
  tracks = unique(temp_df$Track_index)
  tracks = tracks[!is.na(tracks)]

  for (j in tracks){
    if (j=="T1" || j=="T2" || j=="T3" || j=="T4" || j=="T5"){
    df_track_copy = temp_df[temp_df$Track_index==j,]
    track_ext_min = temp_df$Ext_cmyr[temp_df$Track_index==j & temp_df$ExtType_MinOrMax=='Min']
    track_ext_min = track_ext_min[!is.na(track_ext_min)]
    track_ext_max = temp_df$Ext_cmyr[temp_df$Track_index==j & temp_df$ExtType_MinOrMax=='Max']
    track_ext_max = track_ext_max[!is.na(track_ext_max)]
    track_ext_mid = (track_ext_min+track_ext_max)/2
    
    df_track_row_copy = df_track_copy[1,]
    df_track_row_copy$ExtType_MinOrMax ='MidPoint'
    df_track_row_copy$Ext_cmyr = track_ext_mid
    df_track_row_copy$Ext_mmyr = track_ext_mid*10
    DF_midpoints = rbind(DF_midpoints, df_track_row_copy)
  }
  }
}

DF_midpoints = DF_midpoints[order(DF_midpoints$CoralColony, DF_midpoints$Track_index, DF_midpoints$ExtType_MinOrMax), ]
midpoints = DF_midpoints[DF_midpoints$ExtType_MinOrMax=='MidPoint',]
max_points =DF_midpoints[DF_midpoints$ExtType_MinOrMax=='Max',]
min_points =DF_midpoints[DF_midpoints$ExtType_MinOrMax=='Min',]

FIG7_0 =  ggplot(aes( x=Ext_mmyr, 
                      y=TrackDensity,
                      group = CoralColony,
                      color = Location,
                      fill = Location),
                      data = midpoints)+
  
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(3,23), breaks=seq(3,23,1))+
  scale_y_continuous(limits=c(1, 1.9),breaks=seq(1, 1.9,.2))+
  
  geom_point(shape = 22, stroke=2)+
  
  geom_errorbarh(
    aes(xmax = max_points$Ext_mmyr, xmin = min_points$Ext_mmyr),
    linetype='dashed', alpha=0.4)+
  
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'), 
        axis.title = element_text(size = 12), 
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
        legend.position = "none")+
  
  ylab(bquote(atop('Track Density (g'~cm^-3~')')))+
  xlab(bquote(atop('Track Extension (mm'~y^-1~')')))

FIG7_0

# ARROW PLOT - MGA Track Extension Rate vs MGA Track Density midpoints -----------------------------------------------------------------
FIG7 = ggplot(aes(x=Ext_mmyr, 
                 y=TrackDensity,
                 group = CoralColony,
                 color = Location,
                 fill = Location),
                 data = midpoints)+
  
  scale_color_manual(values = color_scheme)+
  scale_fill_manual(values = color_scheme)+
  scale_shape_manual(values=c(4, 22))+
  scale_x_continuous(limits=c(3,23), breaks=seq(3,23,1))+
  scale_y_continuous(limits=c(1, 1.9),breaks=seq(1, 1.9,.2))+
  
  geom_point(shape = 22, stroke=1, size=1)+
  geom_path(arrow = arrow(ends = 'last', 
                          type = 'open',
                          angle=30, 
                          length=unit(4, "mm")), 
            linewidth=1.5, alpha=1)+
  
  geom_errorbarh(
    aes(xmax = max_points$Ext_mmyr, xmin = min_points$Ext_mmyr),
    linetype='dashed', alpha=0.4)+
  
  theme_bw()+
  theme(axis.text = element_text(size = 12, color = 'black'), 
        axis.title = element_text(size = 12), 
        panel.grid.major = element_line(linetype = 'dotted', colour = "black", linewidth = .05),
        panel.grid.minor = element_line(linetype = 'dotted', colour = "black", linewidth = .05), 
        legend.position = "none")+
  
  ylab(bquote(atop('Track Density (g'~cm^-3~')')))+
  xlab(bquote(atop('Track Extension (mm'~y^-1~')')))

FIG7


#Adding coral+track labels -----------------------------------------------------------------
FIG5_1= FIG5+ geom_label_repel(aes(label = paste(CoralColony, Collected_in, sep = " | ")),
                               box.padding   = 0.5, 
                               point.padding = 0.5,
                               segment.color = 'grey70',
                               segment.size = 0.5,
                               segment.alpha =0.8,
                               max.overlaps = 40,
                               size = 1.5,
                               fill='white') 

FIG6_1= FIG6+ geom_label_repel(aes(label = paste(CoralColony, Collected_in, sep = " | ")),
                               box.padding   = 0.5, 
                               point.padding = 0.5,
                               segment.color = 'grey70',
                               segment.size = 0.5,
                               segment.alpha =0.8,
                               max.overlaps = 40,
                               size = 1.5,
                               fill='white') 


FIG7_0_lab = FIG7_0 + geom_label_repel(aes(label = paste(CoralColony, Track_index, YearRangeMin, sep = " | ")),
                                 box.padding   = 0.5, 
                                 point.padding = 0.5,
                                 segment.color = 'grey70',
                                 segment.size = 0.5,
                                 segment.alpha =0.8,
                                 max.overlaps = 40,
                                 size = 2,
                                 fill='white') 
FIG7_0_lab

FIG7_1 = FIG7 + geom_label_repel(aes(label = paste(CoralColony, Track_index, YearRangeMin, sep = " | ")),
                                 box.padding   = 0.5, 
                                 point.padding = 0.5,
                                 segment.color = 'grey70',
                                 segment.size = 0.5,
                                 segment.alpha =0.8,
                                 max.overlaps = 40,
                                 size = 1.5,
                                 fill='white') 



# saving figure -------------------------------------------------------------------------
# ggsave(filename="MGATrack_Extension_Density_Connected.svg",
#        plot = FIG7_1,
#        device = svglite, 
#        width = 297,
#        height = 210,
#        units = "mm")

# PLOT grid with all Ext vs Figures -----------------------------------------------------------------
LFT = plot_grid( FIG6_1, FIG5_1, nrow=2, ncol= 1, labels = c('a)', 'b)'))
RGT = plot_grid(FIG7_0_lab, ncol= 1, labels = c('c)'))
COMPOSITION_FIG = plot_grid(LFT, RGT, ncol=2)
COMPOSITION_FIG

# ggsave(filename="Density_Extension_Comparisson_Bulk_AMR_MGA.svg",
# plot = COMPOSITION_FIG,
# device = svglite, 
# width = 297,
# height = 210,
# units = "mm")


