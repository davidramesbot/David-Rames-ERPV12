-- DR ERP - Supabase Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Clients
create table if not exists clients (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text not null,
  email text,
  address text,
  city text,
  type text default 'individual' check (type in ('individual','company')),
  status text default 'active' check (status in ('active','inactive')),
  balance numeric default 0,
  notes text,
  created_at timestamptz default now()
);

-- Leads
create table if not exists leads (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text not null,
  email text,
  source text,
  status text default 'new' check (status in ('new','contacted','qualified','proposal','won','lost')),
  value numeric,
  notes text,
  assigned_to text,
  created_at timestamptz default now()
);

-- Quotations
create table if not exists quotations (
  id uuid primary key default uuid_generate_v4(),
  number text unique not null,
  client_id uuid references clients(id),
  client_name text,
  date date,
  valid_until date,
  status text default 'draft' check (status in ('draft','sent','approved','rejected','converted')),
  items jsonb default '[]',
  total numeric default 0,
  discount numeric default 0,
  tax numeric default 14,
  notes text,
  created_at timestamptz default now()
);

-- Orders (Sales)
create table if not exists orders (
  id uuid primary key default uuid_generate_v4(),
  number text unique not null,
  client_id uuid references clients(id),
  client_name text,
  date date,
  delivery_date date,
  status text default 'pending' check (status in ('pending','confirmed','in_production','ready','delivered','cancelled')),
  items jsonb default '[]',
  total numeric default 0,
  paid numeric default 0,
  notes text,
  created_at timestamptz default now()
);

-- Payments
create table if not exists payments (
  id uuid primary key default uuid_generate_v4(),
  number text unique,
  client_id uuid references clients(id),
  client_name text,
  order_id uuid references orders(id),
  amount numeric not null,
  method text default 'cash' check (method in ('cash','bank','check','online')),
  date date,
  notes text,
  created_at timestamptz default now()
);

-- Products
create table if not exists products (
  id uuid primary key default uuid_generate_v4(),
  code text unique,
  name text not null,
  category text,
  unit text,
  cost_price numeric default 0,
  sell_price numeric default 0,
  stock numeric default 0,
  min_stock numeric default 0,
  description text,
  created_at timestamptz default now()
);

-- Warehouse Items
create table if not exists warehouse_items (
  id uuid primary key default uuid_generate_v4(),
  code text,
  name text not null,
  category text,
  unit text,
  quantity numeric default 0,
  min_quantity numeric default 0,
  cost_price numeric default 0,
  location text,
  supplier_id uuid,
  created_at timestamptz default now()
);

-- Warehouse Adjustments
create table if not exists warehouse_adjustments (
  id uuid primary key default uuid_generate_v4(),
  item_id uuid references warehouse_items(id),
  item_name text,
  type text check (type in ('in','out','adjustment')),
  quantity numeric,
  reason text,
  date date,
  created_at timestamptz default now()
);

-- Suppliers
create table if not exists suppliers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text,
  email text,
  address text,
  category text,
  balance numeric default 0,
  notes text,
  created_at timestamptz default now()
);

-- Purchase Orders
create table if not exists purchase_orders (
  id uuid primary key default uuid_generate_v4(),
  number text unique not null,
  supplier_id uuid references suppliers(id),
  supplier_name text,
  date date,
  status text default 'pending' check (status in ('pending','ordered','received','cancelled')),
  items jsonb default '[]',
  total numeric default 0,
  notes text,
  created_at timestamptz default now()
);

-- Journal Entries
create table if not exists journal_entries (
  id uuid primary key default uuid_generate_v4(),
  number text unique not null,
  date date,
  description text not null,
  debit_account text,
  credit_account text,
  amount numeric not null,
  reference text,
  created_at timestamptz default now()
);

-- Accounts (Chart of Accounts)
create table if not exists accounts (
  id uuid primary key default uuid_generate_v4(),
  code text unique not null,
  name text not null,
  type text check (type in ('asset','liability','equity','revenue','expense')),
  balance numeric default 0,
  parent_id uuid references accounts(id),
  created_at timestamptz default now()
);

-- Expenses
create table if not exists expenses (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  amount numeric not null,
  category text,
  date date,
  account text,
  reference text,
  created_at timestamptz default now()
);

-- Employees
create table if not exists employees (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  national_id text,
  phone text,
  email text,
  department text,
  position text,
  salary numeric default 0,
  hire_date date,
  status text default 'active' check (status in ('active','inactive')),
  created_at timestamptz default now()
);

-- Attendance
create table if not exists attendance (
  id uuid primary key default uuid_generate_v4(),
  employee_id uuid references employees(id),
  employee_name text,
  date date,
  check_in time,
  check_out time,
  status text default 'present' check (status in ('present','absent','late','half_day')),
  notes text,
  created_at timestamptz default now()
);

-- Leaves
create table if not exists leaves (
  id uuid primary key default uuid_generate_v4(),
  employee_id uuid references employees(id),
  employee_name text,
  type text check (type in ('annual','sick','emergency','unpaid')),
  from_date date,
  to_date date,
  days integer,
  status text default 'pending' check (status in ('pending','approved','rejected')),
  notes text,
  created_at timestamptz default now()
);

-- Payroll
create table if not exists payroll (
  id uuid primary key default uuid_generate_v4(),
  employee_id uuid references employees(id),
  employee_name text,
  month text not null,
  basic_salary numeric default 0,
  bonus numeric default 0,
  deductions numeric default 0,
  net_salary numeric default 0,
  status text default 'pending' check (status in ('pending','paid')),
  created_at timestamptz default now(),
  unique(employee_id, month)
);

-- Production Orders
create table if not exists production_orders (
  id uuid primary key default uuid_generate_v4(),
  number text unique not null,
  order_id uuid references orders(id),
  product_name text not null,
  quantity numeric default 0,
  status text default 'pending' check (status in ('pending','in_progress','completed','paused')),
  start_date date,
  end_date date,
  notes text,
  created_at timestamptz default now()
);

-- Production Stages
create table if not exists production_stages (
  id uuid primary key default uuid_generate_v4(),
  production_order_id uuid references production_orders(id),
  name text not null,
  sequence integer,
  status text default 'pending' check (status in ('pending','in_progress','completed')),
  worker_name text,
  start_date date,
  end_date date,
  notes text,
  created_at timestamptz default now()
);

-- BOM (Bill of Materials)
create table if not exists bom (
  id uuid primary key default uuid_generate_v4(),
  product_name text not null,
  material_name text not null,
  quantity numeric default 0,
  unit text,
  notes text,
  created_at timestamptz default now()
);

-- Quality Checks
create table if not exists quality_checks (
  id uuid primary key default uuid_generate_v4(),
  production_order_id uuid references production_orders(id),
  check_date date,
  inspector text,
  result text check (result in ('pass','fail','conditional')),
  notes text,
  created_at timestamptz default now()
);

-- Vehicles
create table if not exists vehicles (
  id uuid primary key default uuid_generate_v4(),
  plate text unique not null,
  make text,
  model text,
  year integer,
  status text default 'active' check (status in ('active','maintenance','inactive')),
  driver_id uuid,
  notes text,
  created_at timestamptz default now()
);

-- Drivers
create table if not exists drivers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text,
  license_number text,
  license_expiry date,
  status text default 'active' check (status in ('active','inactive')),
  notes text,
  created_at timestamptz default now()
);

-- Trips
create table if not exists trips (
  id uuid primary key default uuid_generate_v4(),
  vehicle_id uuid references vehicles(id),
  driver_id uuid references drivers(id),
  from_location text,
  to_location text,
  date date,
  distance numeric,
  status text default 'planned' check (status in ('planned','in_progress','completed','cancelled')),
  notes text,
  created_at timestamptz default now()
);

-- Enable Row Level Security (RLS) - allow all for now
alter table clients enable row level security;
alter table leads enable row level security;
alter table quotations enable row level security;
alter table orders enable row level security;
alter table employees enable row level security;
alter table warehouse_items enable row level security;
alter table journal_entries enable row level security;
alter table production_orders enable row level security;
alter table vehicles enable row level security;

-- Policies: allow all authenticated users (adjust per role later)
create policy "Allow all" on clients for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on leads for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on quotations for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on orders for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on employees for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on warehouse_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on journal_entries for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on production_orders for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all" on vehicles for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
