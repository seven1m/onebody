# encoding: utf-8

{
  :"af-ZA" => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :cs => { :i18n => { :plural => { :keys => [:one, :few, :other], :rule => lambda { |n| n == 1 ? :one : [2, 3, 4].include?(n) ? :few : :other } } } },
  :da => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :de => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :en => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :"es-419" => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :fr => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :"nl-NL" => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :"pt-BR" => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| [0, 1].include?(n) ? :one : :other } } } },
  :"zh-CN" => { :i18n => { :plural => { :keys => [:other], :rule => lambda { |n| :other } } } }
#  :ro => { :i18n => { :plural => { :keys => [:one, :few, :other], :rule => lambda { |n| n == 1 ? :one : n == 0 ? :few : :other } } } },
#  :ru => { :i18n => { :plural => { :keys => [:one, :few, :many, :other], :rule => lambda { |n| n % 10 == 1 && n % 100 != 11 ? :one : [2, 3, 4].include?(n % 10) && ![12, 13, 14].include?(n % 100) ? :few : n % 10 == 0 || [5, 6, 7, 8, 9].include?(n % 10) || [11, 12, 13, 14].include?(n % 100) ? :many : :other } } } },
}

