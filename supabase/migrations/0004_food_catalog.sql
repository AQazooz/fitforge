create table if not exists public.food_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  serving_size text not null,
  calories integer not null check (calories >= 0),
  protein_g numeric(8,2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(8,2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(8,2) not null default 0 check (fat_g >= 0),
  fiber_g numeric(8,2) not null default 0 check (fiber_g >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.food_catalog enable row level security;

drop policy if exists food_catalog_select_authenticated on public.food_catalog;
create policy food_catalog_select_authenticated on public.food_catalog
for select to authenticated
using (is_active = true);

grant select on public.food_catalog to authenticated;
create index if not exists food_catalog_category_idx on public.food_catalog(category);
create index if not exists food_catalog_name_idx on public.food_catalog(name);

insert into public.food_catalog (name, category, serving_size, calories, protein_g, carbs_g, fat_g, fiber_g)
values
('Chicken breast, grilled','protein','100 g',165,31,0,3.6,0),('Turkey breast, roasted','protein','100 g',135,29,0,1.6,0),('Lean beef, cooked','protein','100 g',217,26,0,12,0),('Salmon, cooked','protein','100 g',206,22,0,12,0),('Tuna, canned in water','protein','100 g',116,26,0,0.8,0),('Egg, whole','protein','1 large',72,6.3,0.4,4.8,0),('Greek yogurt, plain','dairy','170 g',100,17,6,0.7,0),('Cottage cheese, low fat','dairy','100 g',82,11,4,2.3,0),('Milk, semi-skimmed','dairy','250 ml',122,8.3,12,4.8,0),('Whey protein isolate','supplement','30 g',110,25,1,0.5,0),('Rice, white, cooked','carbohydrate','150 g',195,4,42,0.4,0.6),('Oats, dry','carbohydrate','50 g',190,6.5,32,3.5,5),('Potato, baked','carbohydrate','200 g',186,4,42,0.2,3.8),('Sweet potato, baked','carbohydrate','200 g',180,4,41,0.3,6),('Whole wheat bread','carbohydrate','2 slices',180,8,30,3,5),('Banana','fruit','1 medium',105,1.3,27,0.4,3.1),('Apple','fruit','1 medium',95,0.5,25,0.3,4.4),('Orange','fruit','1 medium',62,1.2,15.4,0.2,3.1),('Blueberries','fruit','100 g',57,0.7,14.5,0.3,2.4),('Avocado','fat','100 g',160,2,8.5,14.7,6.7),('Almonds','fat','30 g',174,6.4,6,15,3.2),('Peanut butter','fat','32 g',188,8,7,16,1.9),('Olive oil','fat','1 tbsp',119,0,0,13.5,0),('Broccoli, cooked','vegetable','100 g',35,2.4,7.2,0.4,3.3),('Mixed salad vegetables','vegetable','150 g',45,2,9,0.4,3.5),('Lentils, cooked','legume','150 g',174,13.5,30,0.6,12),('Chickpeas, cooked','legume','150 g',246,13.4,41,3.9,11),('Beans, black, cooked','legume','150 g',198,13.5,35.5,0.8,13.5),('Protein bar','snack','1 bar',200,20,20,7,5),('Dates','fruit','3 dates',200,1.5,54,0.1,4.8)
on conflict do nothing;
