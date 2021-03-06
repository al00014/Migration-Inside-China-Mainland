library(readxl)
library(tidyverse)
library(data.table)
options(scipen = 100)
migration = read_xlsx('china_migration_2005_2010.xlsx') %>% setDT()
migration[,new_resident := 合计 - 省内]
migration[,new_resident_ratio := new_resident/合计]
migration[,sum(new_resident)/sum(合计)]
migration = migration[现住地!='全国']

migration %>% setnames(c('现住地','合计','省内'),
                       c('current_residence','total','inside_province'))
migration_mainland = migration[,!(c('境外','new_resident','new_resident_ratio')),with=F]
migration_mainland = migration_mainland %>% gather(last_province,migration_count,-current_residence,-total,-inside_province) %>% setDT()
migration_mainland[, migration_count := ifelse(is.na(migration_count),inside_province,migration_count)]
migration_mainland_reverse  = migration_mainland[,.(current_residence,last_province,migration_count)] %>% spread(current_residence,migration_count)
migration_mainland_reverse[,total:=rowSums(.SD),.SDcols = setdiff(colnames(migration_mainland_reverse),'last_province')]

m = migration_mainland_reverse[,!(c('last_province','total')),with=F] %>% as.matrix()
diag(m) = 0

migration_mainland_reverse[,move_out := rowSums(m)]
migration_mainland_reverse[,move_out_ratio := move_out/total]
migration_mainland_reverse[,move_out_grp:=ifelse(move_out_ratio>=sum(move_out)/sum(total),'greater','lower')]

migration_mainland_reverse %>% setorder(-move_out_ratio)
p = ggplot(migration_mainland_reverse) + geom_col(aes(x = reorder(last_province,move_out_ratio), y = move_out_ratio,fill = move_out_grp)) + theme_minimal() 
p = p + theme(legend.text = element_text(family = 'HiraginoSansGB-W3'),axis.text.x = element_text(angle = 60, family = 'HiraginoSansGB-W3')) + scale_fill_manual(labels = c('高于平均值','低于平均值'),values=wes_palette(n=2, name="Moonrise3") %>% rev())
p = p + ggtitle('2005-2010年中国大陆各省居民移出比例') + theme(plot.title = element_text(family = 'HiraginoSansGB-W3',hjust = 1,size = 15),legend.title = element_text())
p = p + labs(x = '省份',y = '居民移出比例',fill = '') + theme(axis.title  = element_text(family = 'HiraginoSansGB-W3',size = 8))

ggsave('migration_out.png',width = 25,height = 10,units = 'cm',dpi = 400)

edu_housing = read_xlsx('edu_housing.xlsx') %>% setDT() %>% setnames('受教育程度','edu')
edu_housing = gather(edu_housing, housing_area, count, -edu) %>% setDT()
edu_housing[, housing_area := factor(housing_area, levels = c('8-','9-12','13-16','17-19','20-29','30-39','40-49','50-59','60+'))]
edu_housing[, edu := factor(edu, levels = c('未上过学','小学','初中','高中','大学专科','大学本科','研究生'))]
edu_housing[,density := count/sum(count),edu]
p = ggplot(data = edu_housing) + geom_col(aes(x = housing_area, y = density, fill = edu), position = 'dodge')
p + theme_minimal() + theme(legend.text = element_text(family = 'SourceHanSerifCN-Heavy'),axis.text.x = element_text(angle = 60),title = element_text(family = 'SourceHanSerifCN-Heavy')) + scale_fill_brewer(palette="Set3") + facet_grid(.~edu)
