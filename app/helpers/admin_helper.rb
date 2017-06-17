module AdminHelper
  def small_group_sizes
    [
      [t('admin.settings.small_group_sharing.disable'), 0],
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      20,
      30,
      40,
      50,
      75,
      100,
      150,
      200,
      300,
      400,
      500,
      [t('admin.settings.small_group_sharing.all'), 'all']
    ]
  end
end
